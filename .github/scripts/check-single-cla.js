module.exports = async function checkSingleCla({ github, context, core }) {
  const marker = "<!-- peak-singlecla -->";
  const neededLabel = "cla needed";
  const acceptLine = "I agree that the Single CLA applies to this pull request.";
  const signedForkLine = "I have signed the Single CLA.";

  const { owner, repo } = context.repo;

  async function loadPullRequest() {
    if (context.eventName === "pull_request_target") {
      return context.payload.pull_request;
    }

    const pull_number = context.payload.issue.number;
    const { data } = await github.rest.pulls.get({ owner, repo, pull_number });
    return data;
  }

  async function listComments(issue_number) {
    return await github.paginate(github.rest.issues.listComments, {
      owner,
      repo,
      issue_number,
      per_page: 100,
    });
  }

  function hasExactLine(body, line) {
    const escaped = line.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    return new RegExp(`^\\s*${escaped}\\s*$`, "im").test(body || "");
  }

  function hasNeededLabel(labels) {
    return labels.some((label) => label.name === neededLabel);
  }

  function findCommentWithLine(comments, line) {
    return comments.find((comment) => hasExactLine(comment.body, line));
  }

  async function verifySignedFork(login) {
    const userUrl = `https://raw.githubusercontent.com/${login}/singlecla/main/cla.md`;
    const userResponse = await fetch(userUrl);

    if (!userResponse.ok) return false;

    const userText = await userResponse.text();
    const version = userText.match(/^Version ([0-9]+\.[0-9]+\.[0-9]+)\b/m)?.[1];
    const signed = /^Signed: \/[^{}]+\/$/m.test(userText);

    if (!version || !signed) return false;

    const templateUrl = `https://raw.githubusercontent.com/singlecla/singlecla/v${version}/cla.md`;
    const templateResponse = await fetch(templateUrl);

    if (!templateResponse.ok) return false;

    const templateText = await templateResponse.text();
    // Match singlecla/verify: compare the signed fork with the tagged template
    // after removing only the contributor-specific signature line.
    const withoutSignature = (text) => text.replace(/^Signed: .*$\n?/m, "").trim();

    return withoutSignature(userText) === withoutSignature(templateText);
  }

  async function ensureLabel() {
    try {
      await github.rest.issues.getLabel({ owner, repo, name: neededLabel });
    } catch (error) {
      if (error.status !== 404) throw error;

      await github.rest.issues.createLabel({
        owner,
        repo,
        name: neededLabel,
        color: "b60205",
        description: "Contributor license agreement still needs attention",
      });
    }
  }

  async function addNeededLabel(issue_number, labels) {
    if (hasNeededLabel(labels)) return;

    await ensureLabel();
    await github.rest.issues.addLabels({
      owner,
      repo,
      issue_number,
      labels: [neededLabel],
    });
  }

  async function removeNeededLabel(issue_number, labels) {
    if (!hasNeededLabel(labels)) return;

    await github.rest.issues.removeLabel({
      owner,
      repo,
      issue_number,
      name: neededLabel,
    });
  }

  async function ensureComment(issue_number, comments, body) {
    const existing = comments.find((comment) => comment.user.type === "Bot" && comment.body?.includes(marker));

    if (existing) return;

    await github.rest.issues.createComment({ owner, repo, issue_number, body });
  }

  async function addPlusOneReaction(comment) {
    try {
      await github.rest.reactions.createForIssueComment({
        owner,
        repo,
        comment_id: comment.id,
        content: "+1",
      });
    } catch (error) {
      if (error.status !== 422) throw error;
    }
  }

  function neededComment() {
    return [
      marker,
      "Thanks for contributing to Peak.",
      "",
      "Peak requires the [Single CLA](https://github.com/singlecla/singlecla) for contributions so we have clear ownership of contributions and can keep the option to add other licenses in the future, like MIT or paid corporate plans. Peak is published under AGPLv3, which means the code we have published stays open and free no matter what other licenses we might add later.",
      "",
      "Please choose one of these ways to clear the CLA requirement:",
      "",
      "1. For just this PR, add a PR comment with exactly:",
      "",
      `   \`${acceptLine}\``,
      "",
      "2. For this and future PRs to projects that accept Single CLA, fork https://github.com/singlecla/singlecla to your GitHub account as `singlecla` and commit your signature to `cla.md`, then add a PR comment with exactly:",
      "",
      `   \`${signedForkLine}\``,
    ].join("\n");
  }

  const pullRequest = await loadPullRequest();
  const issue_number = pullRequest.number;
  const login = pullRequest.user.login;
  const labels = pullRequest.labels || [];
  const comments = await listComments(issue_number);
  const authorComments = comments.filter((comment) => comment.user.login === login);
  // The PR template contains example CLA text inside an HTML comment. Ignore
  // comments so keeping the template text does not count as acceptance.
  const bodyWithoutComments = (pullRequest.body || "").replace(/<!--[\s\S]*?-->/g, "");

  if (pullRequest.user.type === "Bot") {
    core.info(`Skipping CLA for bot author ${login}.`);
    return;
  }

  const acceptedComment = findCommentWithLine(authorComments, acceptLine);
  const signedForkComment = findCommentWithLine(authorComments, signedForkLine);
  const acceptedInPullRequest =
    hasExactLine(bodyWithoutComments, acceptLine) ||
    Boolean(acceptedComment);

  const signedFork = await verifySignedFork(login);
  const covered = acceptedInPullRequest || signedFork;

  if (covered) {
    await removeNeededLabel(issue_number, labels);

    if (acceptedComment) {
      await addPlusOneReaction(acceptedComment);
    }

    if (signedFork && signedForkComment) {
      await addPlusOneReaction(signedForkComment);
    }

    core.info(`CLA covered for ${login}.`);
  } else {
    await addNeededLabel(issue_number, labels);
    await ensureComment(issue_number, comments, neededComment());
    core.info(`CLA still needed for ${login}.`);
  }
};
