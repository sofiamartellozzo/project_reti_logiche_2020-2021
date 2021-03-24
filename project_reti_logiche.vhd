----------------------------------------------------------------------------------
-- Progetto di Reti Logiche AA 2020-2021 
-- Politecnico di Milano
-- Sofia Martellozzo, Ilaria Muratori
-- codice persona: 10623060, 10677812
-- matricola: 910488, 911815
----------------------------------------------------------------------------------

    
    library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.std_logic_unsigned.ALL;
    use IEEE.numeric_std.ALL;
    use IEEE.math_real.ALL;
    
    
    entity project_reti_logiche is
        Port ( i_clk : in STD_LOGIC;
               i_rst : in STD_LOGIC;
               i_start : in STD_LOGIC;
               i_data : in STD_LOGIC_VECTOR (7 downto 0);
               o_address : out STD_LOGIC_VECTOR (15 downto 0);
               o_done : out STD_LOGIC;
               o_en : out STD_LOGIC;
               o_we : out STD_LOGIC;
               o_data : out STD_LOGIC_VECTOR (7 downto 0));
    end project_reti_logiche;
    
    architecture Behavioral of project_reti_logiche is
        
 -----------------------------------------------------------------------------------
 -- Stati raggiungibili dalla macchina.
 -----------------------------------------------------------------------------------
    
    type state_type is (
      START,                   -- stato iniziale della MSF
      START_READ,              -- inizio lettura, carico indirizzo della RAM da leggere
      READ,                    -- stato in cui leggo da memoria il pixel 
      DELAY,                   -- stato di attesa aggiornamento segnali, per creare una sorta di delay
      INCREASE,                -- stato in cui incemento il contatore per tener traccia dell'evoluzione dell'elaborazione 
      CALCULATE_MAX_AND_MIN,   -- stato per il calcolo del pixel massimo e minimo
      EQUALIZATION,            -- stato di inizio equalizzazione
      WRITE_EQUALIZATION,      -- stato di fine equalizzazione
      WRITE,                   -- stato in cui scrivo in memoria il pixel equalizzato
      DONE_UP,                 -- stato per notificare fine processo
      DONE_DOWN);              -- stato di attesa inizio eventuiale nuovo processo
                        
-----------------------------------------------------------------------------------
 -- Segnali utilizzati per mantenere dei dati significativi.
-----------------------------------------------------------------------------------
                        
    signal state, current_state : state_type;
    signal current_address : std_logic_vector(15 downto 0);
    signal column : unsigned(7 downto 0);    
    signal row : unsigned(0 to 7);
    signal max_pixel_value,min_pixel_value,delta_value : integer range 0 to 255;
    signal current_pixel_value : unsigned(7 downto 0);
    signal step : integer;
    signal shift_level : integer range 0 to 8:=0; 
    signal dim_img: integer; 
                    
    begin
    process(i_clk ,i_rst)
        
------------------------------------------------------------------------------------
-- Variabili usate per l'equalizzazione
------------------------------------------------------------------------------------
    
    variable temp_pixel : unsigned (15 downto 0); 
    variable new_pixel_value : unsigned (7 downto 0);
          
          begin
          
          
          if(i_rst = '1')then
            
            o_en <= '0';
            o_we <= '0';
            o_done <= '0';
            current_address <= "0000000000000000";
            step <= 0;
            current_pixel_value <= "00000000";
            max_pixel_value <= 0;
            min_pixel_value <= 0;
            row <= "00000000";
            column <= "00000000";
            temp_pixel := "0000000000000000";
            new_pixel_value := "00000000";
            shift_level <= 0;
            dim_img <= 0;
            current_state <= START;
            state <= START;
            

           elsif (i_clk 'event and i_clk='1') then
            case state is 
                when START =>
                    --stato inizio di tutto il processo, dopo un reset e a tocco di clock
                  
                     if (i_start = '1' AND i_rst = '0') then
                         
                             o_en <= '0';
                             o_we <= '0';
                 
                             current_address <= "0000000000000000";
                             step <= 0;
                             current_pixel_value <= "00000000";
                             max_pixel_value <= 0;
                             min_pixel_value <= 0;
                             row <= "00000000";
                             column <= "00000000";
                             temp_pixel := "0000000000000000";
                             new_pixel_value := "00000000";
                             shift_level <= 0;
                             dim_img <= 0;     
                             current_state <= START; 
                             state <= DELAY;                   
                        end if;                    
                    
                when DELAY =>
           
                    if (current_state = START) then
                        state <= START_READ;
                    elsif(current_state = START_READ) then
                        state <= READ;    
                    elsif(current_state = READ) then
                        dim_img <= TO_INTEGER(column)*TO_INTEGER(row);
              			state <= START_READ;
                    elsif(current_state = CALCULATE_MAX_AND_MIN) then
              			state <= CALCULATE_MAX_AND_MIN;
                    elsif (current_state = EQUALIZATION) then
                        state <= EQUALIZATION;
                    elsif (current_state = WRITE_EQUALIZATION) then
                        state <= WRITE;
                    elsif ( current_state = WRITE) then     
                         if (step < (dim_img * 2) + 2) then          --non ho finito di equalizzare, devo rileggere alcuni pixel e trasformarli, controlla num step e quindi if(prima +1 ora ho incrementato prima)
                            state <= START_READ;
                         else
                            state <= DONE_UP;
                         end if;
                    end if;
                    
                when START_READ =>
                        
                     o_en <= '1';
                     o_we <= '0';
                        
                     o_address <= current_address;
                     state <= DELAY;
                     current_state <= START_READ;          
                    
                when INCREASE => 
                    step <= step + 1;
                    current_address <= current_address + "0000000000000001";                                                              
                    state <= DELAY;
                    
                when READ => 
                    
              		o_en <= '1';
              		o_we <= '0';

                    if (step = 0) then           --primo passo, sto leggendo indir 0 quindi il primo byte == il numero di colonne
                        column <= unsigned(i_data);
                        state <= INCREASE;
                        current_state <= READ;
                        
                          
              		elsif ( step = 1) then        --secondo passo, sto leggendo indr 1 quindi il secondo byte == numero righe    
                        row <= unsigned (i_data);
                        state <= INCREASE;
                        current_state <= READ;  
                    
                                             
                    elsif ((step > 1) and (step < dim_img + 2)) then    --qui sono dall'indirizzo 2 in poi, fino a dim+1 ovvero ultimo pixel da leggere da memoria
                        current_pixel_value <= unsigned(i_data);
              			state <= DELAY;
                        current_state <= CALCULATE_MAX_AND_MIN;
                        
                        
              		elsif (step > dim_img + 1) then       --qui sono allo step di inizio equalizzazione e scrittura, il current address si trova alla prima riga vuota (dove scrivere)
                        
                        if (dim_img = 0) then
                            state <= DONE_UP;
                        else    
                            o_address <= std_logic_vector(unsigned(current_address) - dim_img);
                            delta_value <= max_pixel_value - min_pixel_value;  
                            state <= DELAY;
                            current_state <= EQUALIZATION;
                        end if;
                     
                    end if;
                    
     
                    
               when CALCULATE_MAX_AND_MIN =>
                        
              	   o_en <= '1';
                   o_we <= '0';
                   
              	   if (step = 2) then        --essendo il primo pixel max e min li inizializzo pari a questo
                        
                        max_pixel_value <= TO_INTEGER(current_pixel_value); 
                        min_pixel_value <= TO_INTEGER(current_pixel_value);
                        state <= INCREASE;
                        current_state <= READ;
                       
                   else
                        
                        if ( TO_INTEGER(current_pixel_value) > max_pixel_value ) then
                            max_pixel_value <= TO_INTEGER(current_pixel_value);
                        
                        elsif ( TO_INTEGER(current_pixel_value) < min_pixel_value) then
                             min_pixel_value <= TO_INTEGER(current_pixel_value);
                       
                        end if;
                        state <= INCREASE;
                        current_state <= READ;

                   end if; 
                          
                        
                when EQUALIZATION =>
                   
              	   o_en <= '1';
                   o_we <= '0';
                   
                   if (delta_value = 0 ) then
                        shift_level <= 8;
                   elsif ((delta_value = 1) or (delta_value = 2)) then
                        shift_level <= 7;
                   elsif ((delta_value > 2) and (delta_value < 7)) then
                        shift_level <= 6;
                   elsif ((delta_value > 6) and (delta_value < 15)) then
                        shift_level <= 5;
                   elsif ((delta_value > 14) and (delta_value < 31)) then
                        shift_level <= 4;
                   elsif ((delta_value > 30) and (delta_value < 63)) then
                        shift_level <= 3;
                   elsif ((delta_value > 62) and (delta_value < 127)) then
                        shift_level <= 2;
                   elsif ((delta_value > 126) and (delta_value < 255)) then
                        shift_level <= 1;
                   else
                        shift_level <= 0;
                        
                   end if;
                   
                   current_pixel_value <= unsigned(i_data);
                   state <= WRITE_EQUALIZATION;
              
    
                when WRITE_EQUALIZATION =>
              
              	   o_en <= '1';
                   o_we <= '0';

                   temp_pixel := "00000000"&(current_pixel_value - min_pixel_value);
                   temp_pixel := shift_left((temp_pixel),shift_level);    
                   
                   if ( TO_INTEGER(temp_pixel) < 255) then
                        new_pixel_value  := temp_pixel(7 downto 0);
                   else
                        new_pixel_value := "11111111";
                       
                   end if;
                    
                   o_address <= current_address;     --rimetto indirizzo in fondo, primo libero dove scrivere new pixel
                   state <= DELAY;
                   current_state <= WRITE_EQUALIZATION;

                    
               when WRITE =>
                   
              		 o_en <= '1';
                     o_we <= '1';
              		 
                     o_data <= std_logic_vector(new_pixel_value);
                     state <= INCREASE;
                     current_state <= WRITE;
                    
                    
                when DONE_UP =>
                    
                    o_done <= '1';
                    o_en <= '0';
                    o_we <= '0';

                    if (i_start = '0') then
                        state <= DONE_DOWN;
                    else
                        state <= DONE_UP;
                    end if;
                    
                    
                when DONE_DOWN =>
                        
                    o_done <= '0';

                    if (i_start = '1') then
                        state <= START;
                    else
                        state <= DONE_DOWN;
                    end if;   
                
             end case;
           end if;
        end process; 
  end Behavioral;


