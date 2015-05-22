module LearnSubmit
  class Submission
    attr_reader :user, :git, :message

    def self.create(message: nil)
      new(message: message).create
    end

    def initialize(message:)
      @user    = set_user
      @message = message
    end

    def create
      setup_submission
      submit!
    end

    private

    def set_user
      _login, token = Netrc.read['learn-config']
      LearnWeb::Client.new(token: token).me
    end

    def setup_submission
      LearnSubmit::Submission::GitInteractor.new(
        username: user.username, message: message
      ).commit_and_push
    end

    def submit!
      raise 'Not implemented yet!'
    end
  end
end
