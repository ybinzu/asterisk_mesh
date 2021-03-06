require 'test_helper'

class DialplanTest < Minitest::Test
  include AsteriskMesh::Config
  include AsteriskMesh::NodeName

  def setup
    @dialplan = AsteriskMesh::Dialplan.new
    @node_from = { 'name' => 'test', 'host' => 'test.pro',
                   'operator_prefix' => 'operator', 'extension' => '2XX',
                   'primary_digits' => 3 }

    @node_from_dyn = @node_from.dup
    @node_from_dyn.delete('host')

    @node_to = { 'host' => 'n3.host.pro', 'extension' => '3XXX',
                 'name' => 'n3.host.pro',
                 'prefix' => '55', 'primary_digits' => 4 }

    @node_to_dyn = @node_to.dup
    @node_to_dyn.delete('host')

    @static_node = { 'host' => 'n0.static', 'extension' => '1XX',
                     'name' => 'n0.static', 'prefix' => '0',
                     'primary_digits' => 3 }

    @password = SecureRandom.hex
  end

  def test_to_mesh_static
    result = @dialplan.to_mesh_static(@node_from, @node_to)

    assert_equal(<<~DIALPLAN, result)
      exten => _553XXX,1,NoOp
      same => n,Set(CALLERID(all)=55${CALLERID(num):-3})
      same => n,Dial(IAX2/mesh-n3.host.pro/${EXTEN:-4},60,rtT)
      same => n,Hangup

    DIALPLAN
  end

  def test_from_mesh_static
    result = @dialplan.from_mesh_static(@node_to)

    assert_equal(<<~DIALPLAN, result)
      exten => _3XXX,1,NoOp
      same => n,Dial(SIP/${EXTEN},60,rtT)
      same => n,Hangup

    DIALPLAN
  end

  def test_to_mesh_context
    assert_equal("[to-mesh]\n", @dialplan.to_mesh_context)
  end

  def test_from_mesh_context
    assert_equal("[from-mesh]\n", @dialplan.from_mesh_context)
  end

  def test_to_mesh_dynamic
    result = @dialplan.to_mesh_dynamic(@node_from_dyn, @node_to)

    assert_equal(<<~DIALPLAN, result)
      exten => _553XXX,1,NoOp
      same => n,Set(CALLERID(all)=55${CALLERID(num):-3})
      same => n,Dial(IAX2/mesh-test-n3.host.pro/${EXTEN:-4},60,rtT)
      same => n,Hangup

    DIALPLAN
  end

  def test_to_mesh_dynamic_dynamic_hangup
    assert_equal("same => n,Hangup\n\n",
                 @dialplan.to_mesh_dynamic_dynamic_hangup)
  end

  def test_to_mesh_dynamic_dynamic
    result = @dialplan.to_mesh_dynamic_dynamic(@static_node, @node_from_dyn,
                                               @node_to_dyn)

    assert_equal(<<~DIAL, result)
      same => n,Dial(IAX2/mesh-test-n0.static/${EXTEN:-4},60,rtT)
    DIAL
  end

  def test_to_mesh_dynamic_dynamic_exten
    result = @dialplan.to_mesh_dynamic_dynamic_exten(@node_from_dyn,
                                                     @node_to_dyn)

    assert_equal(<<~DIAL, result)
      exten => _553XXX,1,NoOp
      same => n,Set(CALLERID(all)=55${CALLERID(num):-3})
    DIAL
  end
end
