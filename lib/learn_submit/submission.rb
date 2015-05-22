module LearnSubmit
  class Submission
    attr_reader :git

    def self.create(message: nil)
      new(message: message).create
    end

    def initialize(message:)
      _login, token = Netrc.read['learn-config']

      @client  = LearnWeb::Client.new(token: token)
      @git     = LearnSubmit::Submission::GitInteractor.new(username: user, message: message)
    end

    def create
      commit_and_push!
      submit!
    end

    def user
      @user ||= client.me
    end

    private

    def commit_and_push!
      git.commit_and_push
    end

    def submit!
      repo_name = git.repo_name
      client.issue_pull_request(repo_name: repo_name)
    end
  end
end
