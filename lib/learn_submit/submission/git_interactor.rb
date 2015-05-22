module LearnSubmit
  class Submission
    class GitInteractor
      attr_reader :username, :git, :message

      LEARN_ORG_NAMES = [
        'learn-co',
        'learn-co-curriculum',
        'learn-co-students'
      ]

      def initialize(username:, message:)
        @username = username
        @message  = message || 'Done.'

        set_git_dir
      end

      def commit_and_push
        check_remote
        add_changes
        commit_changes

        push!
      end

      private

      def set_git_dir
        begin
          @git = Git.open(FileUtils.pwd)
        rescue ArgumentError => e
          if e.mssage.match(/path does not exist/)
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
        self.remote_name = if !git.remote.url.match(url.username)
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
        new_url = new_url.gsub(/#{LEARN_ORG_NAMES.join('|').gsub('-','\-')}/,'')
        git.add_remote(name, url)

        name
      end

      def add_changes
        git.add(all: true)
      end

      def commit_changes
        git.commit(message)
      end

      def push!
        git.push
      end
    end
  end
end
