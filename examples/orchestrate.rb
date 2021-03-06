# Simple example on how Dynflow could be used for simple infrastructure orchestration

module Orchestrate

  class CreateInfrastructure < Dynflow::Action

    def plan
      sequence do
        concurrence do
          plan_action(CreateMachine, 'host1', 'db')
          plan_action(CreateMachine, 'host2', 'storage')
        end
        plan_action(CreateMachine,
                    'host3',
                    'web_server',
                    :db_machine => 'host1',
                    :storage_machine => 'host2')
      end
      sleep 2
    end
  end

  class CreateMachine < Dynflow::Action

    def plan(name, profile, config_options = {})
      prepare_disk = plan_action(PrepareDisk, 'name' => name)
      create_vm    = plan_action(CreateVM,
                                 :name => name,
                                 :disk => prepare_disk.output['path'])
      plan_action(AddIPtoHosts, :name => name, :ip => create_vm.output[:ip])
      plan_action(ConfigureMachine,
                  :ip => create_vm.output[:ip],
                  :profile => profile,
                  :config_options => config_options)
      plan_self(:name => name)
    end

    def finalize
      puts "We've create a machine #{input[:name]}"
    end

  end

  class PrepareDisk < Dynflow::Action

    input_format do
      param :name
    end

    output_format do
      param :path
    end

    def run
      sleep(rand(5))
      output[:path] = "/var/images/#{input[:name]}.img"
    end

  end

  class CreateVM < Dynflow::Action

    input_format do
      param :name
      param :disk
    end

    output_format do
      param :ip
    end

    def run
      sleep(rand(5))
      output[:ip] = "192.168.100.#{rand(256)}"
    end

  end

  class AddIPtoHosts < Dynflow::Action

    input_format do
      param :ip
    end

    def run
      sleep(rand(5))
    end

  end

  class ConfigureMachine < Dynflow::Action

    input_format do
      param :ip
      param :profile
      param :config_options
    end

    def run
      # for demonstration of resuming after error
      if Orchestrate.should_fail?
        Orchestrate.should_pass!
        raise "temporary unavailabe"
      end

      sleep(rand(5))
    end

  end


  # for simulation of the execution failing for the first time
  def self.should_fail?
    ! @should_pass
  end

  def self.should_pass!
    @should_pass = true
  end

end
