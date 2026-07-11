namespace = namespaces.create_approved :public, name: "@public"

gems.with namespace: do
  index = namespace.default_index
  _1.parse :activesupport, index, "8.1.1 base64:>= 0,bigdecimal:>= 0,concurrent-ruby:>= 1.3.1&~> 1.0,connection_pool:>= 2.2.5,drb:>= 0,i18n:< 2&>= 1.6,json:>= 0,logger:>= 0"
  _1.parse :activerecord, index, "8.1.1 activemodel:= 8.1.1,activesupport:= 8.1.1,timeout:>= 0"

  _1.parse :actionview, index,
    "7.0.9 activesupport:= 7.0.9,builder:~> 3.1,erubi:~> 1.4,rails-dom-testing:~> 2.0,rails-html-sanitizer:>= 1.2.0&~> 1.1|checksum:9f4e9e04eac9e38752ffb9746cb6d5ef3b833998ec966c4734c34ec3776970ad,ruby:>= 2.7.0",
    "7.0.10 activesupport:= 7.0.10,builder:~> 3.1,erubi:~> 1.4,rails-dom-testing:~> 2.0,rails-html-sanitizer:>= 1.2.0&~> 1.1|checksum:e5a9475ccfcde80dddf7ced701f44aedc4f8262286051db84ae2c48322ec000e,ruby:>= 2.7.0",
    "7.1.6 activesupport:= 7.1.6,builder:~> 3.1,cgi:>= 0,erubi:~> 1.11,rails-dom-testing:~> 2.2,rails-html-sanitizer:~> 1.6|checksum:11147d81f90465ae062b2a77805c6f8f446e044e309c51bd9449bdbd43edf566,ruby:>= 2.7.0",
    "7.2.3 activesupport:= 7.2.3,builder:~> 3.1,cgi:>= 0,erubi:~> 1.11,rails-dom-testing:~> 2.2,rails-html-sanitizer:~> 1.6|checksum:1f427d7a41b43804d7250911535740451b9c32b6416239d87e6dab9d5948ecb2,ruby:>= 3.1.0",
    "8.0.4 activesupport:= 8.0.4,builder:~> 3.1,erubi:~> 1.11,rails-dom-testing:~> 2.2,rails-html-sanitizer:~> 1.6|checksum:5bd3c41ee7a59e14cf062bb5e4ee53c9a253d12fc13c8754cae368012e1a1648,ruby:>= 3.2.0",
    "8.1.0 activesupport:= 8.1.0,builder:~> 3.1,erubi:~> 1.11,rails-dom-testing:~> 2.2,rails-html-sanitizer:~> 1.6|checksum:b7e8770a5aacd389a3c04916d29609a53459447fcbf747150437136d44c1d1f3,ruby:>= 3.2.0",
    "8.1.0.rc1 activesupport:= 8.1.0.rc1,builder:~> 3.1,erubi:~> 1.11,rails-dom-testing:~> 2.2,rails-html-sanitizer:~> 1.6|checksum:cc0361bef45e52120b15e8bf6d155c49ffde9c674de537d6523d4cf6aed2cb3a,ruby:>= 3.2.0",
    "8.1.1 activesupport:= 8.1.1,builder:~> 3.1,erubi:~> 1.11,rails-dom-testing:~> 2.2,rails-html-sanitizer:~> 1.6|checksum:ca480c8b099dea0862b0934f24182b84c2d29092e7dbf464fb3e6d4eb9b468dc,ruby:>= 3.2.0",
    "8.1.2 activesupport:= 8.1.2,builder:~> 3.1,erubi:~> 1.11,rails-dom-testing:~> 2.2,rails-html-sanitizer:~> 1.6|checksum:80455b2588911c9b72cec22d240edacb7c150e800ef2234821269b2b2c3e2e5b,ruby:>= 3.2.0"

  _1.parse :oaken, index, gems.oaken_lines
end
