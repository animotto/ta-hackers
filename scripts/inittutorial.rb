require 'securerandom'

##
# Reproduces initial network topology from tutorial
# Use the -f argument for fast mode (finish nodes immediately)
class Inittutorial < Sandbox::Script
  TUTORIAL_FINISHED = 10000
  COORDS_RAND_RANGE = -10..10
  MISSION_TUTORIAL_ID = 1

  def main
    @fast_mode = !@args[0].nil? && @args[0] == '-f'

    unless @game.connected?
      @logger.error(NOT_CONNECTED)
      return
    end

    @fast_mode_string = @fast_mode ? 'enabled' : 'disabled'
    @logger.log("Fast mode #{@fast_mode_string}")

    @logger.log('Loading player info')
    @game.player.load

    if @game.player.tutorial == TUTORIAL_FINISHED
      @logger.error('Tutorial is finished')
      return
    end

    node_core = @game.player.net.detect { |node| node.type == Hackers::NodeTypes::Core::TYPE }
    unless node_core
      @logger.error('Node Core not found')
      return
    end

    if @game.player.profile.builders < 2
      @logger.log('Buy builder')
      @game.buy_builder
    end

    upgrade_node(node_core) if node_core.level < 2

    node_parent = create_node(Hackers::NodeTypes::Sentry::TYPE, node_core)
    node_parent = create_node(Hackers::NodeTypes::Database::TYPE, node_parent)
    node_parent = create_node(Hackers::NodeTypes::BitcoinMine::TYPE, node_parent)
    node_parent = create_node(Hackers::NodeTypes::Compiler::TYPE, node_parent)

    start_mission(MISSION_TUTORIAL_ID)
    @logger.log('Loading missions info')
    @game.missions.load
    finish_mission(MISSION_TUTORIAL_ID)

    node_parent = create_node(Hackers::NodeTypes::BitcoinMixer::TYPE, node_parent)
    node_parent = create_node(Hackers::NodeTypes::Evolver::TYPE, node_parent)

    @logger.log('Finishing tutorial')
    @game.player.set_tutorial(TUTORIAL_FINISHED)
  rescue Hackers::ExceptionError => e
    @logger.error(e.description)
  rescue Hackers::RequestError => e
    @logger.error(e)
  end

  private

  def create_node(type, parent)
    node_type = @game.node_types.get(type)
    node = @game.player.net.detect { |n| n.type == node_type.type }
    unless node
      node = parent.create(node_type.type)
      @logger.log("Create #{node_type.name} (#{node.id})")
      node.x = ::SecureRandom.rand(COORDS_RAND_RANGE)
      node.y = ::SecureRandom.rand(COORDS_RAND_RANGE)
      node.z = ::SecureRandom.rand(COORDS_RAND_RANGE)
      coords = ::Kernel.format('%+d %+d %+d', node.x, node.y, node.z)
      @logger.log("Update #{node_type.name} coordinates to [#{coords}]")
      @game.player.net.update

      if @fast_mode
        finish_node(node)
        return node
      end

      time = node_type.completion_time(1)
      sleep(time)
      return node
    end

    @logger.log("#{node_type.name}: skipping")
    node
  end

  def upgrade_node(node)
    node_type = @game.node_types.get(node.type)
    @logger.log("Upgrade #{node_type.name} (#{node.id})")
    node.upgrade

    if @fast_mode
      finish_node(node)
      return node
    end

    time = node_type.completion_time(node.level + 1)
    sleep(time)
    node
  end

  def finish_node(node)
    node_type = @game.node_types.get(node.type)
    @logger.log("Finish #{node_type.name}")
    node.finish
    node
  end

  def start_mission(id)
    @logger.log("Start mission (#{id})")
    @game.missions.start(id)
  end

  def finish_mission(id)
    mission = @game.missions.get(id)
    mission_type = @game.missions_list.get(id)
    @logger.log("Finish mission (#{id})")
    mission.attack
    mission.money = mission_type.additional_money
    mission.bitcoins = mission_type.additional_bitcoins
    mission.finish
    mission.update
  end

  def sleep(seconds)
    @logger.log("Waiting #{seconds} seconds")
    ::Kernel.sleep(seconds)
  end
end
