require_relative 'test_helper'

ENV['RACK_ENV'] = 'test'
require 'dynflow/web_console'

require 'rack/test'

module Dynflow
  describe 'web console' do

    include Rack::Test::Methods
    include WorldInstance

    let :execution_plan_id do
      world.trigger(Support::CodeWorkflowExample::FastCommit, 'sha' => 'abc123').
          tap { |o| o.finished.wait }.
          id
    end

    let :app do
      world = self.world
      Dynflow::WebConsole.setup do
        set :world, world
      end
    end

    it 'lists all execution plans' do
      get '/'
      assert last_response.ok?
    end

    it 'show an execution plan' do
      get "/#{execution_plan_id}"
      assert last_response.ok?
    end
  end
end
