#guard(:rspec, all_on_start: true) do #, cli: '--format nested --debug --color' do
guard :rspec, cmd: "bundle exec rspec" do
  watch(%r{^spec/.+[_-]spec\.rb$})
  watch(%r{^lib/rubyserial/(.+)\.rb$})       { |m| "spec/lib/#{m[1]}_spec.rb" }
  watch('spec/spec_helper.rb')    { "spec" }
  watch('lib/rubyserial.rb')    { "spec" }
end
