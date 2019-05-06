require 'yaml'
require 'json'

module LearnSubmit
  class Submission
    attr_reader :git, :client, :file_path, :message, :save, :token, :dot_learn

    def self.create(message: nil, save: false)
      new(message: message, save: save).create
    end

    def initialize(message:, save:)
      _login, @token = Netrc.read['learn-config']

      @client    = LearnWeb::Client.new(token: @token)
      @git       = LearnSubmit::Submission::GitInteractor.new(username: user.username, message: message)
      @file_path = File.expand_path('~/.learn-submit-tmp')
      @message   = message
      @save      = save
      @dot_learn = YAML.load(File.read("#{FileUtils.pwd}/.learn")) if File.exist?("#{FileUtils.pwd}/.learn")
    end

    def create
      setup_tmp_file

      commit_and_push!

      if !save
        submit!
      end
    end

    def setup_tmp_file
      FileUtils.touch(file_path)
      File.write(file_path, '')
    end

    def cleanup_tmp_file
      File.write(file_path, 'Done.')
    end

    def user
      @user ||= client.me
    end

    private

    def commit_and_push!
      File.write(file_path, 'Pushing your code to GitHub...')

      if dot_learn && dot_learn['github'] == false
        git.commit
      else
        git.commit_and_push
      end

      # Just to give GitHub a second to register the repo changes
      sleep(1)
    end

    def submit!(retries=3)
      if retries >= 2
        puts 'Submitting lesson...'
        File.write(file_path, 'Opening a Pull Request...')
      end
      repo_name   = git.repo_name
      branch_name = git.branch_name
      sleep(1)

      begin
        pr_response = Timeout::timeout(15) do
          client.issue_pull_request(repo_name: repo_name, branch_name: branch_name, message: message)
        end
      rescue Timeout::Error
        if retries > 0
          puts "It seems like there's a problem connecting to Learn. Trying again..."
          submit!(retries-1)
        else
          puts "Sorry, there's a problem reaching Learn right now. Please try again."
          File.write(file_path, 'ERROR: Error connecting to learn.')
          exit 1
        end
      end

      case pr_response.status
      when 200
        puts 'Done.'
        File.write(file_path, 'Done.')
        exit
      when 404
        puts 'Sorry, it seems like there was a problem connecting with Learn. Please try again.'
        File.write(file_path, 'ERROR: Error connecting to learn.')
        exit 1
      else
        if retries > 0
          sleep(2)
          submit!(0)
        else
          puts pr_response.message

          if pr_response.message.match(/looks the same/)
            File.write(file_path, 'ERROR: Nothing to submit')
          else
            File.write(file_path, 'Done.')
          end

          exit 1
        end
      end
    end
  end
end
