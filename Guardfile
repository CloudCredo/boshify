guard :rspec, spec_paths: ['spec/unit'] do
  watch(%r{^spec/unit/.+_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$})     { |m| "spec/unit/#{m[1]}_spec.rb" }
  watch('spec/spec_helper.rb')  { "spec/unit" }
  notification :tmux, color_location: 'status-right-bg', display_message: true
end
