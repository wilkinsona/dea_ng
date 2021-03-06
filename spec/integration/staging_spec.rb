require "spec_helper"

describe "Staging an app", :type => :integration, :requires_warden => true do
  let(:nats) { NatsHelper.new }

  describe "staging a simple sinatra app" do
    let(:unstaged_url) { "http://localhost:9999/unstaged/sinatra" }
    let(:staged_url) { "http://localhost:9999/staged/sinatra" }

    it "packages a ruby binary and the app's gems" do
      response = nats.request("staging", {
        "async" => false,
        "app_id" => "some-app-id",
        "properties" => {},
        "download_uri" => unstaged_url,
        "upload_uri" => staged_url
      })

      response["task_log"].should include("Your bundle is complete!")
      response["error"].should be_nil

      download_tgz(staged_url) do |dir|
        Dir.entries("#{dir}/app/vendor").should include("ruby-1.9.2")
        Dir.entries("#{dir}/app/vendor/bundle/ruby/1.9.1/gems").should =~ %w(
          .
          ..
          bundler-1.3.2
          rack-1.5.1
          rack-protection-1.3.2
          sinatra-1.3.4
          tilt-1.3.3
        )
      end
    end

    def download_tgz(url)
      dir = Dir.mktmpdir
      system "curl #{url} > #{dir}/staged_app.tgz 1> /dev/null"
      system "cd #{dir} && tar xzvf staged_app.tgz 1> /dev/null"
      yield dir
      FileUtils.rm_rf(dir)
    end
  end
end
