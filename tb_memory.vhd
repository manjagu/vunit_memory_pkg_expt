library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.com_context;
use vunit_lib.memory_pkg.all;
use vunit_lib.avalon_pkg.all;
use vunit_lib.bus_master_pkg.all;

library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

entity tb_avalonmm_slave is
  generic(runner_cfg     : string;
          encoded_tb_cfg : string
         );
end entity;

architecture tb of tb_avalonmm_slave is

  -----------------------------------------------------------------------------
  -- Constants
  -----------------------------------------------------------------------------
  type tb_cfg_t is record
    data_width         : positive;
    cycles             : positive;
  end record tb_cfg_t;

  impure function decode(encoded_tb_cfg : string) return tb_cfg_t is
  begin
    return (data_width         => positive'value(get(encoded_tb_cfg, "data_width")),
            cycles             => positive'value(get(encoded_tb_cfg, "cycles")));
  end function decode;

  constant tb_cfg : tb_cfg_t := decode(encoded_tb_cfg);

  constant CLK_TO_TIME : time := 1 ns * 1e9;

  constant CLK_100_FREQ   : real := 100000000.0;
  constant CLK_100_PERIOD : time := CLK_TO_TIME / CLK_100_FREQ;

  constant MEM_DATA_WIDTH_BITS   : natural := tb_cfg.data_width;
  constant MEM_SIZE_BYTES        : natural := natural(tb_cfg.data_width / 8) * natural(tb_cfg.cycles);
  constant MEM_ADDR_WIDTH        : natural := natural(ceil(log2(real(tb_cfg.cycles))));

  -----------------------------------------------------------------------------
  -- VUnit Setup
  -----------------------------------------------------------------------------

  constant tb_logger : logger_t := get_logger("tb");

  constant memory : memory_t := new_memory;
  constant buf    : buffer_t := allocate(memory, MEM_SIZE_BYTES); -- @suppress "Unused declaration"

  -----------------------------------------------------------------------------
  -- Clock and Reset Signals
  -----------------------------------------------------------------------------

  signal clk_100 : std_logic := '1';

  signal test_signal_read_data : std_logic_vector(MEM_DATA_WIDTH_BITS-1 downto 0);
  signal test_signal_write_data : std_logic_vector(MEM_DATA_WIDTH_BITS-1 downto 0);
  signal test_signal_write_data_z1 : std_logic_vector(MEM_DATA_WIDTH_BITS-1 downto 0);
  signal test_address : std_logic_vector(MEM_ADDR_WIDTH-1 downto 0);

begin
  -----------------------------------------------------------------------------
  -- Clocks and resets
  -----------------------------------------------------------------------------
  clk_100 <= not clk_100 after CLK_100_PERIOD / 2.0;

  -----------------------------------------------------------------------------
  -- Testing process
  -----------------------------------------------------------------------------

  main : process
  begin
    test_runner_setup(runner, runner_cfg);
    wait until rising_edge(clk_100);

    -----------------------------------------------------------------------------
    -- The lines below set the test output verbosity, which can help debug
    -----------------------------------------------------------------------------

        set_format(display_handler, verbose, true);
        show(tb_logger, display_handler, verbose);
    
        wait until rising_edge(clk_100);

    -----------------------------------------------------------------------------

    -----------------------------------------------------------------------------
    -- This is a very basic test that proves we can read and write using the
    -- memory VCI in the same loop. Signals, rather than variables, were used so
    -- all could be seen in a simulator.
    -----------------------------------------------------------------------------
    if run("In_Loop_Write_Then_Read") then
      
      for i in 0 to tb_cfg.cycles-1 loop
        test_address <= std_logic_vector(to_unsigned(i, MEM_ADDR_WIDTH)); -- for sim viewing only
        test_signal_write_data <= std_logic_vector(to_unsigned(i, MEM_DATA_WIDTH_BITS));
        test_signal_write_data_z1 <= test_signal_write_data; -- this was done for simulator viewing; yes, variables could have been used
        wait until rising_edge(clk_100);        
        write_word(memory, i, test_signal_write_data);
        test_signal_read_data <= read_word(memory, i, MEM_DATA_WIDTH_BITS/8);
        check_equal(test_signal_read_data, test_signal_write_data_z1);
      end loop;

    -----------------------------------------------------------------------------
    -- This test writes to memory in one loop and reads back the data in another.
    -- This fails when multi-byte transactions occur.
    -----------------------------------------------------------------------------
    elsif run("Out_Of_Loop_Write_Then_Read") then
      info(tb_logger, "Writing...");
      
      -- Write the data to memory
      for i in 0 to tb_cfg.cycles-1 loop
        test_address <= std_logic_vector(to_unsigned(i, MEM_ADDR_WIDTH)); -- for sim viewing only
        test_signal_write_data <= std_logic_vector(to_unsigned(i, MEM_DATA_WIDTH_BITS));
        wait until rising_edge(clk_100);        
        write_word(memory, i, test_signal_write_data);
      end loop;
      
      wait until rising_edge(clk_100);

      -- Read the data back and check it              
      info(tb_logger, "Reading...");
      for i in 0 to tb_cfg.cycles-1 loop
        test_address <= std_logic_vector(to_unsigned(i, MEM_ADDR_WIDTH)); -- for sim viewing only
        test_signal_read_data <= read_word(memory, i, MEM_DATA_WIDTH_BITS/8);
        wait until rising_edge(clk_100);        
        check_equal(test_signal_read_data, i);
      end loop;
          
    end if;

    test_runner_cleanup(runner);        -- Simulation ends here
    wait;
  end process;

  -- Set up watchdog so the TB doesn't run forever
  test_runner_watchdog(runner, 10 us);
end architecture;
