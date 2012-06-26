function hold_en_init_xblock(blk, varargin)

defaults = {'hold_period', 2, 'explicit_clk_rate', 'off', 'input_clk_period', 1, 'counter_out', 'off'};


hold_period = get_var('hold_period', 'defaults', defaults, varargin{:});
explicit_clk_rate = get_var('explicit_clk_rate', 'defaults', defaults, varargin{:}); 
    % when this is off, infer clock rate from input, then input_clk_period is pratically disabled
input_clk_period = get_var('input_clk_period', 'defaults', defaults, varargin{:});
    % simulation only 
counter_out = get_var('counter_out', 'defaults', defaults, varargin{:});


%% inports
sync_in = xInport('sync_in');

%% outports
en_out = xOutport('en_out');
if strcmp(counter_out, 'on')
    counter_outport = xOutport('counter_out');
end

%% diagram

if hold_period == 1
    
    en_out.bind(sync_in);
    if strcmp(counter_out , 'on')
        counter_outport.bind(sync_in);
    end
    if ~isempty(blk) && ~strcmp(blk(1),'/')
        clean_blocks(blk);
        fmtstr=sprintf('Pass-through\nhold period: %d\nexplicit clk period:%s , input clk period:%d',hold_period, explicit_clk_rate, input_clk_period);
        set_param(blk,'AttributesFormatString',fmtstr);
    end
    return;
end

% block: untitled/Constant
xlsub1_Constant_out1 = xSignal('xlsub1_Constant_out1');
xlsub1_Constant = xBlock(struct('source', 'Constant', 'name', 'Constant'), ...
                         struct('const', 0), ...
                         {}, ...
                         {xlsub1_Constant_out1});

                     
                     
xlsub1_Logical_out1 = xSignal('xlsub1_Logical_out1');
% block: untitled/Counter1
xlsub1_Counter1_out1 = xSignal('xlsub1_Counter1_out1');
if strcmp(explicit_clk_rate, 'on')
    xlsub1_Counter1 = xBlock(struct('source', 'Counter', 'name', 'Counter1'), ...
                             struct('cnt_type', 'Count Limited', ...
                                    'cnt_to', 0, ...
                                    'operation', 'Down', ...
                                    'start_count', hold_period-1, ...
                                    'n_bits', nextpow2(hold_period), ...
                                    'rst', 'on',...
                                    'explicit_period', 'on', ...
                                    'period', input_clk_period), ...
                             {xlsub1_Logical_out1}, ...
                             {xlsub1_Counter1_out1});
else
    xlsub1_Counter1 = xBlock(struct('source', 'Counter', 'name', 'Counter1'), ...
                             struct('cnt_type', 'Count Limited', ...
                                    'cnt_to', 0, ...
                                    'operation', 'Down', ...
                                    'start_count', hold_period-1, ...
                                    'n_bits', nextpow2(hold_period), ...
                                    'rst', 'on',...
                                    'explicit_period', 'on', ...
                                    'period', 1), ...
                             {xlsub1_Logical_out1}, ...
                             {xlsub1_Counter1_out1});
end


% block: untitled/Logical
xlsub1_Relational_out1 = xSignal('xlsub1_Relational_out1');
xlsub1_Logical = xBlock(struct('source', 'Logical', 'name', 'Logical'), ...
                        struct('logical_function', 'OR'), ...
                        {xlsub1_Relational_out1, sync_in}, ...
                        {xlsub1_Logical_out1});
                    
                    
% block: untitled/Relational
xlsub1_Relational = xBlock(struct('source', 'Relational', 'name', 'Relational'), ...
                           struct('mode', 'a=b', ...
                                  'latency', 0), ...
                           {xlsub1_Counter1_out1, xlsub1_Constant_out1}, ...
                           {xlsub1_Relational_out1});


xConnector(en_out, xlsub1_Logical_out1);
if strcmp(counter_out , 'on')
    xConnector(counter_outport, xlsub1_Counter1_out1);
end


if ~isempty(blk) && ~strcmp(blk(1),'/')
    clean_blocks(blk);
    fmtstr=sprintf('hold period: %d\nexplicit clk period:%s , input clk period:%d',hold_period, explicit_clk_rate, input_clk_period);
    set_param(blk,'AttributesFormatString',fmtstr);
end

end

