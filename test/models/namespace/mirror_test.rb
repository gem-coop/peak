require "test_helper"

class Namespace::MirrorTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  def mirror
    namespaces.rubygems.mirror
  end

  def sync
    perform_enqueued_jobs do
      mirror.sync
    end
  end

  def enqueued_gem_names
    enqueued_jobs.filter_map do |job|
      job[:args].first["name"] if job[:job] == Namespace::Mirror::GemImportJob
    end
  end

  test "normalizes a url without a trailing slash" do
    no_url = namespaces.gemcoop.build_mirror(url: nil)
    assert_equal false, no_url.valid?

    other = namespaces.gemcoop.create_mirror!(url: "https://gem.coop")
    assert_equal "https://gem.coop/", other.reload.url
  end

  def stub_rake(body)
    stub_request(:get, "https://rubygems.org/info/rake").
      to_return(status: 200, body:)
    stub_request(:get, "https://rubygems.org/api/v1/versions/rake.json").
      to_return(status: 200, body: file_fixture("rake.json"), headers: {'content-type': "application/json"})

    body.lines.each do |line|
      next if line =~ /---/
      v = line.split(" ", 2).first
      stub_request(:get, "https://rubygems.org/quick/Marshal.4.8/rake-#{v}.gemspec.rz").
        to_return(status: 200, body: file_fixture("gemspecs/quick/rake-#{v}.gemspec.rz"))
    end
  end

  def stub_versions(body)
    stub_request(:get, "https://rubygems.org/versions").
      to_return(status: 200, body:)
  end

  def assert_versions(name, versions)
    db_versions = mirror.namespace.gems.find_by(name:).versions.map(&:ref)
    assert_equal versions, db_versions
  end

  test "sync, compact, sync" do
    stub_rake <<~END
      ---
      13.0.0.pre.1 |checksum:0976e0a51d1420686cd3adaac3e92850e3b660b5ed4bb25fd9ca235f062ba808,ruby:>= 2.2,rubygems:>= 1.3.2
      13.0.0 |checksum:06195347674818f4979ba22561a24b9d07f692758e4aabe5bcb12da55e058816,ruby:>= 2.2,rubygems:>= 1.3.2
      13.0.1 |checksum:292a08eb3064e972e3e07e4c297d54a93433439ff429e58a403ae05584fad870,ruby:>= 2.2,rubygems:>= 1.3.2
      13.1.0 |checksum:be6a3e1aa7f66e6c65fa57555234eb75ce4cf4ada077658449207205474199c6,ruby:>= 2.3
      13.2.0 |checksum:f6c1ae27806904a33733be246568ae0937204f1386d8f0774bf3f81c6d269b53,ruby:>= 2.3
      13.2.1 |checksum:46cb38dae65d7d74b6020a4ac9d48afed8eb8149c040eccf0523bec91907059d,ruby:>= 2.3
      13.3.0 |checksum:96f5092d786ff412c62fde76f793cc0541bd84d2eb579caa529aa8a059934493,ruby:>= 2.3
    END

    stub_versions <<~END
      ---
      rake 13.0.0.pre.1,13.0.0,13.0.1,13.0.2,13.0.3,13.0.4,13.0.5,13.0.6,13.1.0,13.2.0 1320aaaaaaaaaaaaaaaaaaaaaaaaaaaa
      rake 13.2.1 1321aaaaaaaaaaaaaaaaaaaaaaaaaaaa
      rake 100.0.0 10000aaaaaaaaaaaaaaaaaaaaaaaaaaa
      rake -100.0.0
      rake 13.3.0 1330aaaaaaaaaaaaaaaaaaaaaaaaaaaa
    END
    sync
    assert_versions "rake", %w[13.0.0.pre.1 13.0.0 13.0.1 13.1.0 13.2.0 13.2.1 13.3.0]

    # no changes, compact
    stub_versions <<~END
      ---
      rake 13.0.0.pre.1,13.0.0,13.0.1,13.0.2,13.0.3,13.0.4,13.0.5,13.0.6,13.1.0,13.2.0,13.2.1,13.3.0 1330aaaaaaaaaaaaaaaaaaaaaaaaaaaa
    END
    sync
    assert_versions "rake", %w[13.0.0.pre.1 13.0.0 13.0.1 13.1.0 13.2.0 13.2.1 13.3.0]
  end

  test "sync, yank all but one, compact, sync" do
    stub_versions <<~END
      ---
      rake 13.0.0.pre.1,13.0.0,13.0.1,13.0.2,13.0.3,13.0.4,13.0.5,13.0.6,13.1.0,13.2.0 1320aaaaaaaaaaaaaaaaaaaaaaaaaaaa
      rake 13.2.1 1321aaaaaaaaaaaaaaaaaaaaaaaaaaaa
      rake 100.0.0 10000aaaaaaaaaaaaaaaaaaaaaaaaaaa
      rake -100.0.0
      rake 13.3.0 1330aaaaaaaaaaaaaaaaaaaaaaaaaaaa
    END
    stub_rake <<~END
      ---
      13.0.0.pre.1 |checksum:0976e0a51d1420686cd3adaac3e92850e3b660b5ed4bb25fd9ca235f062ba808,ruby:>= 2.2,rubygems:>= 1.3.2
      13.0.0 |checksum:06195347674818f4979ba22561a24b9d07f692758e4aabe5bcb12da55e058816,ruby:>= 2.2,rubygems:>= 1.3.2
      13.0.1 |checksum:292a08eb3064e972e3e07e4c297d54a93433439ff429e58a403ae05584fad870,ruby:>= 2.2,rubygems:>= 1.3.2
      13.1.0 |checksum:be6a3e1aa7f66e6c65fa57555234eb75ce4cf4ada077658449207205474199c6,ruby:>= 2.3
      13.2.0 |checksum:f6c1ae27806904a33733be246568ae0937204f1386d8f0774bf3f81c6d269b53,ruby:>= 2.3
      13.2.1 |checksum:46cb38dae65d7d74b6020a4ac9d48afed8eb8149c040eccf0523bec91907059d,ruby:>= 2.3
      13.3.0 |checksum:96f5092d786ff412c62fde76f793cc0541bd84d2eb579caa529aa8a059934493,ruby:>= 2.3
    END
    sync
    assert_versions "rake", %w[13.0.0.pre.1 13.0.0 13.0.1 13.1.0 13.2.0 13.2.1 13.3.0]

    # yank, compact
    stub_versions <<~END
      ---
      rake 13.3.0 1330aaaaaaaaaaaaaaaaaaaaaaaaaaaa
    END
    stub_rake <<~END
      ---
      13.3.0 |checksum:96f5092d786ff412c62fde76f793cc0541bd84d2eb579caa529aa8a059934493,ruby:>= 2.3
    END
    sync
    assert_versions "rake", %w[13.3.0]
  end

  test "sync, publish, publish, yank, compact, sync" do
    stub_versions <<~END
      ---
      rake 13.0.0.pre.1,13.0.0,13.0.1,13.0.2,13.0.3,13.0.4,13.0.5,13.0.6,13.1.0,13.2.0 1320aaaaaaaaaaaaaaaaaaaaaaaaaaaa
      rake 13.2.1 1321aaaaaaaaaaaaaaaaaaaaaaaaaaaa
      rake 100.0.0 10000aaaaaaaaaaaaaaaaaaaaaaaaaaa
      rake -100.0.0
    END
    stub_rake <<~END
      ---
      13.0.0.pre.1 |checksum:0976e0a51d1420686cd3adaac3e92850e3b660b5ed4bb25fd9ca235f062ba808,ruby:>= 2.2,rubygems:>= 1.3.2
      13.0.0 |checksum:06195347674818f4979ba22561a24b9d07f692758e4aabe5bcb12da55e058816,ruby:>= 2.2,rubygems:>= 1.3.2
      13.0.1 |checksum:292a08eb3064e972e3e07e4c297d54a93433439ff429e58a403ae05584fad870,ruby:>= 2.2,rubygems:>= 1.3.2
      13.1.0 |checksum:be6a3e1aa7f66e6c65fa57555234eb75ce4cf4ada077658449207205474199c6,ruby:>= 2.3
      13.2.0 |checksum:f6c1ae27806904a33733be246568ae0937204f1386d8f0774bf3f81c6d269b53,ruby:>= 2.3
      13.2.1 |checksum:46cb38dae65d7d74b6020a4ac9d48afed8eb8149c040eccf0523bec91907059d,ruby:>= 2.3
    END
    sync
    assert_versions "rake", %w[13.0.0.pre.1 13.0.0 13.0.1 13.1.0 13.2.0 13.2.1]

    # publish 13.3.0, compact
    stub_versions <<~END
      ---
      rake 13.0.0.pre.1,13.0.0,13.0.1,13.0.2,13.0.3,13.0.4,13.0.5,13.0.6,13.1.0,13.2.0,13.2.1,13.3.0 1330aaaaaaaaaaaaaaaaaaaaaaaaaaaa
    END
    stub_rake <<~END
      ---
      13.0.0.pre.1 |checksum:0976e0a51d1420686cd3adaac3e92850e3b660b5ed4bb25fd9ca235f062ba808,ruby:>= 2.2,rubygems:>= 1.3.2
      13.0.0 |checksum:06195347674818f4979ba22561a24b9d07f692758e4aabe5bcb12da55e058816,ruby:>= 2.2,rubygems:>= 1.3.2
      13.0.1 |checksum:292a08eb3064e972e3e07e4c297d54a93433439ff429e58a403ae05584fad870,ruby:>= 2.2,rubygems:>= 1.3.2
      13.1.0 |checksum:be6a3e1aa7f66e6c65fa57555234eb75ce4cf4ada077658449207205474199c6,ruby:>= 2.3
      13.2.0 |checksum:f6c1ae27806904a33733be246568ae0937204f1386d8f0774bf3f81c6d269b53,ruby:>= 2.3
      13.2.1 |checksum:46cb38dae65d7d74b6020a4ac9d48afed8eb8149c040eccf0523bec91907059d,ruby:>= 2.3
      13.3.0 |checksum:96f5092d786ff412c62fde76f793cc0541bd84d2eb579caa529aa8a059934493,ruby:>= 2.3
    END

    # ensure we aren't importing existing versions again
    stub_request(:get, "https://rubygems.org/quick/Marshal.4.8/rake-13.0.0.gemspec.rz").
      to_return(status: 404, body: "")

    sync
    assert_versions "rake", %w[13.0.0.pre.1 13.0.0 13.0.1 13.1.0 13.2.0 13.2.1 13.3.0]
  end

  test "sync, yank, publish, compact, sync" do
    stub_versions <<~END
      ---
      rake 13.0.0.pre.1,13.0.0,13.0.1,13.0.2,13.0.3,13.0.4,13.0.5,13.0.6,13.1.0,13.2.0 1320aaaaaaaaaaaaaaaaaaaaaaaaaaaa
      rake 13.2.1 1321aaaaaaaaaaaaaaaaaaaaaaaaaaaa
      rake 100.0.0 10000aaaaaaaaaaaaaaaaaaaaaaaaaaa
    END
    stub_rake <<~END
      ---
      13.0.0.pre.1 |checksum:0976e0a51d1420686cd3adaac3e92850e3b660b5ed4bb25fd9ca235f062ba808,ruby:>= 2.2,rubygems:>= 1.3.2
      13.0.0 |checksum:06195347674818f4979ba22561a24b9d07f692758e4aabe5bcb12da55e058816,ruby:>= 2.2,rubygems:>= 1.3.2
      13.0.1 |checksum:292a08eb3064e972e3e07e4c297d54a93433439ff429e58a403ae05584fad870,ruby:>= 2.2,rubygems:>= 1.3.2
      13.1.0 |checksum:be6a3e1aa7f66e6c65fa57555234eb75ce4cf4ada077658449207205474199c6,ruby:>= 2.3
      13.2.0 |checksum:f6c1ae27806904a33733be246568ae0937204f1386d8f0774bf3f81c6d269b53,ruby:>= 2.3
      13.2.1 |checksum:46cb38dae65d7d74b6020a4ac9d48afed8eb8149c040eccf0523bec91907059d,ruby:>= 2.3
      100.0.0 |checksum:96f5092d786ff412c62fde76f793cc0541bd84d2eb579caa529aa8a059934493,ruby:>= 2.3
    END
    sync
    assert_versions "rake", %w[13.0.0.pre.1 13.0.0 13.0.1 13.1.0 13.2.0 13.2.1 100.0.0]

    # yank 100.0.0, publish 13.3.0, compact
    stub_versions <<~END
      ---
      rake 13.0.0.pre.1,13.0.0,13.0.1,13.0.2,13.0.3,13.0.4,13.0.5,13.0.6,13.1.0,13.2.0,13.2.1,13.3.0 1330aaaaaaaaaaaaaaaaaaaaaaaaaaaa
    END
    stub_rake <<~END
      ---
      13.0.0.pre.1 |checksum:0976e0a51d1420686cd3adaac3e92850e3b660b5ed4bb25fd9ca235f062ba808,ruby:>= 2.2,rubygems:>= 1.3.2
      13.0.0 |checksum:06195347674818f4979ba22561a24b9d07f692758e4aabe5bcb12da55e058816,ruby:>= 2.2,rubygems:>= 1.3.2
      13.0.1 |checksum:292a08eb3064e972e3e07e4c297d54a93433439ff429e58a403ae05584fad870,ruby:>= 2.2,rubygems:>= 1.3.2
      13.1.0 |checksum:be6a3e1aa7f66e6c65fa57555234eb75ce4cf4ada077658449207205474199c6,ruby:>= 2.3
      13.2.0 |checksum:f6c1ae27806904a33733be246568ae0937204f1386d8f0774bf3f81c6d269b53,ruby:>= 2.3
      13.2.1 |checksum:46cb38dae65d7d74b6020a4ac9d48afed8eb8149c040eccf0523bec91907059d,ruby:>= 2.3
      13.3.0 |checksum:96f5092d786ff412c62fde76f793cc0541bd84d2eb579caa529aa8a059934493,ruby:>= 2.3
    END
    sync
    assert_versions "rake", %w[13.0.0.pre.1 13.0.0 13.0.1 13.1.0 13.2.0 13.2.1 13.3.0]
  end

  test "sync, publish, yank, publish, compact, sync" do
    stub_versions <<~END
      ---
      rake 13.0.0.pre.1,13.0.0,13.0.1,13.0.2,13.0.3,13.0.4,13.0.5,13.0.6,13.1.0,13.2.0 1320aaaaaaaaaaaaaaaaaaaaaaaaaaaa
      rake 13.2.1 1321aaaaaaaaaaaaaaaaaaaaaaaaaaaa
    END
    stub_rake <<~END
      ---
      13.0.0.pre.1 |checksum:0976e0a51d1420686cd3adaac3e92850e3b660b5ed4bb25fd9ca235f062ba808,ruby:>= 2.2,rubygems:>= 1.3.2
      13.0.0 |checksum:06195347674818f4979ba22561a24b9d07f692758e4aabe5bcb12da55e058816,ruby:>= 2.2,rubygems:>= 1.3.2
      13.0.1 |checksum:292a08eb3064e972e3e07e4c297d54a93433439ff429e58a403ae05584fad870,ruby:>= 2.2,rubygems:>= 1.3.2
      13.1.0 |checksum:be6a3e1aa7f66e6c65fa57555234eb75ce4cf4ada077658449207205474199c6,ruby:>= 2.3
      13.2.0 |checksum:f6c1ae27806904a33733be246568ae0937204f1386d8f0774bf3f81c6d269b53,ruby:>= 2.3
      13.2.1 |checksum:46cb38dae65d7d74b6020a4ac9d48afed8eb8149c040eccf0523bec91907059d,ruby:>= 2.3
    END
    sync
    assert_versions "rake", %w[13.0.0.pre.1 13.0.0 13.0.1 13.1.0 13.2.0 13.2.1]

    # publish 100, yank 100, publish 13.3.0, compact
    stub_versions <<~END
      ---
      rake 13.0.0.pre.1,13.0.0,13.0.1,13.0.2,13.0.3,13.0.4,13.0.5,13.0.6,13.1.0,13.2.0,13.2.1,13.3.0 1330aaaaaaaaaaaaaaaaaaaaaaaaaaaa
    END
    stub_rake <<~END
      ---
      13.0.0.pre.1 |checksum:0976e0a51d1420686cd3adaac3e92850e3b660b5ed4bb25fd9ca235f062ba808,ruby:>= 2.2,rubygems:>= 1.3.2
      13.0.0 |checksum:06195347674818f4979ba22561a24b9d07f692758e4aabe5bcb12da55e058816,ruby:>= 2.2,rubygems:>= 1.3.2
      13.0.1 |checksum:292a08eb3064e972e3e07e4c297d54a93433439ff429e58a403ae05584fad870,ruby:>= 2.2,rubygems:>= 1.3.2
      13.1.0 |checksum:be6a3e1aa7f66e6c65fa57555234eb75ce4cf4ada077658449207205474199c6,ruby:>= 2.3
      13.2.0 |checksum:f6c1ae27806904a33733be246568ae0937204f1386d8f0774bf3f81c6d269b53,ruby:>= 2.3
      13.2.1 |checksum:46cb38dae65d7d74b6020a4ac9d48afed8eb8149c040eccf0523bec91907059d,ruby:>= 2.3
      13.3.0 |checksum:96f5092d786ff412c62fde76f793cc0541bd84d2eb579caa529aa8a059934493,ruby:>= 2.3
    END
    sync
    assert_versions "rake", %w[13.0.0.pre.1 13.0.0 13.0.1 13.1.0 13.2.0 13.2.1 13.3.0]
  end

  test "sync, publish, publish, yank, publish, compact, sync" do
    stub_versions <<~END
      ---
      rake 13.0.0.pre.1,13.0.0,13.0.1,13.1.0,13.2.0 1320aaaaaaaaaaaaaaaaaaaaaaaaaaaa
    END
    stub_rake <<~END
      ---
      13.0.0.pre.1 |checksum:0976e0a51d1420686cd3adaac3e92850e3b660b5ed4bb25fd9ca235f062ba808,ruby:>= 2.2,rubygems:>= 1.3.2
      13.0.0 |checksum:06195347674818f4979ba22561a24b9d07f692758e4aabe5bcb12da55e058816,ruby:>= 2.2,rubygems:>= 1.3.2
      13.0.1 |checksum:292a08eb3064e972e3e07e4c297d54a93433439ff429e58a403ae05584fad870,ruby:>= 2.2,rubygems:>= 1.3.2
      13.1.0 |checksum:be6a3e1aa7f66e6c65fa57555234eb75ce4cf4ada077658449207205474199c6,ruby:>= 2.3
      13.2.0 |checksum:f6c1ae27806904a33733be246568ae0937204f1386d8f0774bf3f81c6d269b53,ruby:>= 2.3
    END
    sync
    assert_versions "rake", %w[13.0.0.pre.1 13.0.0 13.0.1 13.1.0 13.2.0]

    # publish 13.2.1, publish 100, yank 100, publish 13.3.0, compact
    stub_versions <<~END
      ---
      rake 13.0.0.pre.1,13.0.0,13.0.1,13.1.0,13.2.0,13.2.1,13.3.0 1330aaaaaaaaaaaaaaaaaaaaaaaaaaaa
    END
    stub_rake <<~END
      ---
      13.0.0.pre.1 |checksum:0976e0a51d1420686cd3adaac3e92850e3b660b5ed4bb25fd9ca235f062ba808,ruby:>= 2.2,rubygems:>= 1.3.2
      13.0.0 |checksum:06195347674818f4979ba22561a24b9d07f692758e4aabe5bcb12da55e058816,ruby:>= 2.2,rubygems:>= 1.3.2
      13.0.1 |checksum:292a08eb3064e972e3e07e4c297d54a93433439ff429e58a403ae05584fad870,ruby:>= 2.2,rubygems:>= 1.3.2
      13.1.0 |checksum:be6a3e1aa7f66e6c65fa57555234eb75ce4cf4ada077658449207205474199c6,ruby:>= 2.3
      13.2.0 |checksum:f6c1ae27806904a33733be246568ae0937204f1386d8f0774bf3f81c6d269b53,ruby:>= 2.3
      13.2.1 |checksum:46cb38dae65d7d74b6020a4ac9d48afed8eb8149c040eccf0523bec91907059d,ruby:>= 2.3
      13.3.0 |checksum:96f5092d786ff412c62fde76f793cc0541bd84d2eb579caa529aa8a059934493,ruby:>= 2.3
    END
    sync
    assert_versions "rake", %w[13.0.0.pre.1 13.0.0 13.0.1 13.1.0 13.2.0 13.2.1 13.3.0]
  end

  test "queues an import job for every gem in the versions list" do
    stub_versions <<~END
      ---
      rake 13.0.0 1000aaaaaaaaaaaaaaaaaaaaaaaaaaaa
      oaken 1.0.0 1001aaaaaaaaaaaaaaaaaaaaaaaaaaaa
      unpwn 2.0.0 1002aaaaaaaaaaaaaaaaaaaaaaaaaaaa
    END

    mirror.sync

    assert_equal %w[rake oaken unpwn], enqueued_gem_names
    assert_equal 2, mirror.reload.last_seen_line
  end

  test "resumes from the checkpoint line instead of requeueing every gem" do
    stub_versions <<~END
      ---
      rake 13.0.0 1000aaaaaaaaaaaaaaaaaaaaaaaaaaaa
      oaken 1.0.0 1001aaaaaaaaaaaaaaaaaaaaaaaaaaaa
      unpwn 2.0.0 1002aaaaaaaaaaaaaaaaaaaaaaaaaaaa
    END

    mirror.sync
    assert_equal %w[rake oaken unpwn], enqueued_gem_names

    enqueued_jobs.clear
    mirror.sync

    assert_empty enqueued_gem_names
    assert_equal 2, mirror.reload.last_seen_line
  end

  test "resyncs from the top when the checkpointed line no longer matches" do
    stub_versions <<~END
      ---
      rake 13.0.0 1000aaaaaaaaaaaaaaaaaaaaaaaaaaaa
      oaken 1.0.0 1001aaaaaaaaaaaaaaaaaaaaaaaaaaaa
    END
    mirror.sync
    assert_equal %w[rake oaken], enqueued_gem_names

    # after compacting the checkpoint doesn't match
    stub_versions <<~END
      ---
      rake 13.0.0 1000aaaaaaaaaaaaaaaaaaaaaaaaaaaa
      unpwn 2.0.0 1002aaaaaaaaaaaaaaaaaaaaaaaaaaaa
    END
    enqueued_jobs.clear
    mirror.sync

    assert_equal %w[rake unpwn], enqueued_gem_names
  end

  test "force_all clears the checkpoint and requeues every gem" do
    stub_versions <<~END
      ---
      rake 13.0.0 1000aaaaaaaaaaaaaaaaaaaaaaaaaaaa
      oaken 1.0.0 1001aaaaaaaaaaaaaaaaaaaaaaaaaaaa
    END
    mirror.sync
    assert_equal 1, mirror.reload.last_seen_line

    enqueued_jobs.clear
    mirror.sync(force_all: true)

    assert_equal %w[rake oaken], enqueued_gem_names
    assert_equal 1, mirror.reload.last_seen_line
  end
end
