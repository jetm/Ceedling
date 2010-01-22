require File.dirname(__FILE__) + '/../unit_test_helper'
require 'generator_test_results'


class GeneratorTestResultsTest < Test::Unit::TestCase

  def setup
    objects = create_mocks(:configurator, :yaml_wrapper, :streaminator)
    @utils = GeneratorTestResults.new(objects)
  end

  def teardown
  end

  
  should "complain if output from test fixture includes messed up statistics" do

    # no ignore count
    raw_unity_output1 = %Q[
      13 Tests 0 Failures
      ].left_margin(0)

    @configurator.expects.extension_executable.returns('.exe')
    @streaminator.expects.stderr_puts("ERROR: Results from test fixture 'TestIng.exe' are missing or are malformed.", Verbosity::ERRORS)

    assert_raise(RuntimeError){ @utils.process_and_write_results(raw_unity_output1, 'project/build/results/TestIng.pass', 'files/tests/TestIng.c') }

    # 'Test' not pluralized
    raw_unity_output2 = %Q[
      13 Test 0 Failures 3 Ignored
      ].left_margin(0)

    @configurator.expects.extension_executable.returns('.out')
    @streaminator.expects.stderr_puts("ERROR: Results from test fixture 'TestIcular.out' are missing or are malformed.", Verbosity::ERRORS)

    assert_raise(RuntimeError){ @utils.process_and_write_results(raw_unity_output2, 'project/build/results/TestIcular.pass', 'files/tests/TestIcular.c') }
  end


  should "write a mixture of test results to a .fail file" do
    
    # test fixture output with blank lines and junk past the statistics line
    raw_unity_output = %Q[
           
      test_a_file.c:13:test_a_single_thing:pay no attention to the test behind the curtain IGNORED
      test_a_file.c:18:test_another_thing:pay no attention to the test behind the curtain IGNORED
      test_a_file.c:35:test_your_knowledge:Expected TRUE was FALSE
      test_a_success_case::: PASS
      
      test_a_file.c:47:test_another_thing:Expected FALSE was TRUE
      test_a_file.c:53:test_some_non_void_param_stuff:pay no attention to the test behind the curtain IGNORED
      test_a_file.c:60:test_some_multiline_test_case_action:pay no attention to the test behind the curtain IGNORED
      
      test_another_success_case::: PASS
      test_yet_another_success_case::: PASS
      test_a_file.c:65:test_a_final_thing:BOOM!
      10 Tests 3 Failures 4 Ignored
      FAIL
      // a random comment to be ignored
      ].left_margin(0)
    
    expected_hash = {
      :counts => {:total => 10, :failed => 3, :ignored => 4, :passed => 3},
      :source => {:path => 'files/tests', :file => 'test_a_file.c'},
      :messages => {
        :failures => ['35:test_your_knowledge:Expected TRUE was FALSE', '47:test_another_thing:Expected FALSE was TRUE', '65:test_a_final_thing:BOOM!'],
        :ignores => [
          '13:test_a_single_thing:pay no attention to the test behind the curtain',
          '18:test_another_thing:pay no attention to the test behind the curtain',
          '53:test_some_non_void_param_stuff:pay no attention to the test behind the curtain',
          '60:test_some_multiline_test_case_action:pay no attention to the test behind the curtain'
          ],
        :successes => [
          'test_a_success_case',
          'test_another_success_case',
          'test_yet_another_success_case'
          ]
        }
      }
    
    @configurator.expects.extension_testfail.returns('.fail')
    
    @yaml_wrapper.expects.dump('project/build/results/test_a_file.fail', expected_hash)
    
    @utils.process_and_write_results(raw_unity_output, 'project/build/results/test_a_file.pass', 'files/tests/test_a_file.c')
    
  end


  should "write a mixture of test results to a .pass file" do
    
    # clean test fixture output
    raw_unity_output = %Q[
      test_a_file.c:13:test_a_single_thing:pay no attention to the test behind the curtain IGNORED
      test_a_file.c:18:test_another_thing:pay no attention to the test behind the curtain IGNORED
      test_a_success_case::: PASS
      test_a_file.c:60:test_some_multiline_test_case_action:pay no attention to the test behind the curtain IGNORED
      test_another_success_case::: PASS
      test_yet_another_success_case::: PASS
      6 Tests 0 Failures 3 Ignored
      OK
      ].left_margin(0)
    
    expected_hash = {
      :counts => {:total => 6, :failed => 0, :ignored => 3, :passed => 3},
      :source => {:path => 'files/tests', :file => 'test_eez.c'},
      :messages => {
        :failures => [],
        :ignores => [
          '13:test_a_single_thing:pay no attention to the test behind the curtain',
          '18:test_another_thing:pay no attention to the test behind the curtain',
          '60:test_some_multiline_test_case_action:pay no attention to the test behind the curtain'
          ],
        :successes => [
          'test_a_success_case',
          'test_another_success_case',
          'test_yet_another_success_case'
          ]
        }
      }
    
    @yaml_wrapper.expects.dump('project/build/results/test_eez.pass', expected_hash)
    
    @utils.process_and_write_results(raw_unity_output, 'project/build/results/test_eez.pass', 'files/tests/test_eez.c')
    
  end

end
