function delay_slr_init_xblock(DelayLen)



%% inports
xlsub2_In1 = xInport('In1');

%% outports
xlsub2_Out1 = xOutport('Out1');

%% diagram

% block: delay_7/delay_slr/delay_slr
xlsub2_delay_slr = xBlock(struct('source', 'Delay', 'name', 'delay_slr'), ...
                          struct('latency', DelayLen), ...
                          {xlsub2_In1}, ...
                          {xlsub2_Out1});



end

