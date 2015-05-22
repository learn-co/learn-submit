module LearnSubmit
  class Submission
    attr_reader :git, :client

    def self.create(message: nil)
      new(message: message).create
    end

    def initialize(message:)
      _login, token = Netrc.read['learn-config']

      @client  = LearnWeb::Client.new(token: token)
      @git     = LearnSubmit::Submission::GitInteractor.new(username: user.username, message: message)
    end

    def create
      commit_and_push!
      submit!

      puts 'Done.'
    end

    def user
      @user ||= client.me
    end

    private

    def commit_and_push!
      git.commit_and_push
    end

    def submit!
      puts 'Submitting lesson...'
      repo_name   = git.repo_name
      branch_name = git.branch_name
      client.issue_pull_request(repo_name: repo_name, branch_name: branch_name)
    end
  end
end
