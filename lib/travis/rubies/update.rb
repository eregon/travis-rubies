require 'travis/rubies'
require 'shellwords'
require 'gh'

module Travis::Rubies
  class Update
    def self.build(ruby, options = {})
      new(options).build(ruby)
    end

    def initialize(options = {})
      @github_token = options[:github_token] || ENV.fetch("GITHUB_TOKEN")
      @branches     = options[:branches]     || ['build']
      @slug         = options[:slug]         || 'travis-ci/travis-rubies'
      @commit       = options[:commit]
      @commit_url   = options[:commit_url]
    end

    def build(ruby)
      content = "export RUBY=%s\n" % Shellwords.escape(ruby)
      message = "trigger new build for %s" % ruby
      message << " (#{@commit[0,7]})"      if @commit
      message << "\n#{@commit_url}" if @commit_url
      @branches.each { |branch| write("build_info.sh", content, message, branch); sleep 2 }
    end

    def write(path, content, message, branch)
      gh      = GH.with(token: @github_token)
      payload = { message: message, path: path, content: Base64.strict_encode64(content), branch: branch }
      current = gh["repos/#{@slug}/contents/#{path}?ref=#{branch}"]
      gh.put("repos/#{@slug}/contents/#{path}", payload.merge('sha' => current['sha']))
    rescue GH::Error => error
      raise error unless payload
      gh.put("repos/#{@slug}/contents/#{path}", payload) rescue raise(error)
    end
  end
end
