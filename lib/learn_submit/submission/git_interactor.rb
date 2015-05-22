module LearnSubmit
  class Submission
    class GitInteractor
      attr_reader   :username, :git, :message
      attr_accessor :remote_name

      LEARN_ORG_NAMES = [
        'learn-co',
        'learn-co-curriculum',
        'learn-co-students'
      ]

      def initialize(username:, message:)
        @username = username
        @message  = message || 'Done.'
        @git      = set_git
      end

      def commit_and_push
        check_remote
        add_changes
        commit_changes

        push!
      end

      def repo_name
        url = git.remote(remote_name).url
        url.gsub(/^.+\w+\/(.*?)(?:\.git)?$/, '')
      end

      private

      def set_git
        begin
          Git.open(FileUtils.pwd)
        rescue ArgumentError => e
          if e.message.match(/path does not exist/)
            puts "It doesn't look like you're in a lesson directory."
            puts 'Please cd into an appropriate directory and try again.'

            exit
          else
            puts 'Sorry, something went wrong. Please try again.'
            exit
          end
        end
      end

      def check_remote
        self.remote_name = if !git.remote.url.match(/#{username}/)
          fix_remote!
        else
          git.remote.name
        end
      end

      def fix_remote!
        old_remote_name = git.remote.name
        old_url         = git.remote.url

        add_backup_remote(old_remote_name, old_url)
        add_correct_remote
      end

      def add_backup_remote(name, url)
        git.add_remote("#{name}-bak", url)
      end

      def add_correct_remote(name, url)
        new_url = url.gsub(/#{LEARN_ORG_NAMES.join('|').gsub('-','\-')}/, username)
        git.add_remote(name, new_url)

        name
      end

      def add_changes
        git.add(all: true)
      end

      def commit_changes
        git.commit(message)
      end

      def push!
        push_remote = git.remote(self.remote_name)
        git.push(push_remote)
      end
    end
  end
end
