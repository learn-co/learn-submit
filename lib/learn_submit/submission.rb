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

      pr_response = client.issue_pull_request(repo_name: repo_name, branch_name: branch_name)
      case pr_response.status
      when 200
        puts "Done."
      when 404
        puts 'Sorry, it seems like there was a problem connecting with Learn. Please try again.'
      else
        puts pr_response.message
      end
    end
  end
end
