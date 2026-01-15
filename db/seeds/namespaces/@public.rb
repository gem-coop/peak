namespace = namespaces.create :public, name: "@public"

gems.with namespace: do
  _1.parse :activesupport, "8.1.1 base64:>= 0,bigdecimal:>= 0,concurrent-ruby:>= 1.3.1&~> 1.0,connection_pool:>= 2.2.5,drb:>= 0,i18n:< 2&>= 1.6,json:>= 0,logger:>="
  _1.parse :activerecord, "8.1.1 activemodel:= 8.1.1,activesupport:= 8.1.1,timeout:>= 0"

  _1.parse :oaken,
    "0.9.1 |checksum:86c502949e539dd53e40e66664502c7a0bda537eccdfa9ae426f0c90c354ba03,ruby:>= 3.0.0",
    "1.0.0 |checksum:e89249bc4f6cd3ab9b5e3abdc06c377fa772e6bcb3005cc09ff044bb8d3f1dc2,ruby:>= 3.2"
end
