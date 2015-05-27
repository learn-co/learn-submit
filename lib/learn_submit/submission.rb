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

      # Just to give GitHub a second to register the repo changes
      sleep(1)
    end

    def submit!(retries=3)
      puts 'Submitting lesson...'
      repo_name   = git.repo_name
      branch_name = git.branch_name

      begin
        Timeout::timeout(15) do
          pr_response = client.issue_pull_request(repo_name: repo_name, branch_name: branch_name)
        end
      rescue Timeout::Error
        if retries > 0
          puts "It seems like there's a problem connecting to Learn. Trying again..."
          submit!(retries-1)
        else
          puts "Sorry, there's a problem reaching Learn right now. Please try again."
          exit
        end
      end

      case pr_response.status
      when 200
        puts "Done."
        exit
      when 404
        puts 'Sorry, it seems like there was a problem connecting with Learn. Please try again.'
        exit
      else
        puts pr_response.message

        if retries > 0
          puts "Trying again..."
          submit!(retries-1)
        end
      end
    end
  end
end
