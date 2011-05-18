function convert_of0(bit_width_i, binary_point_i, bit_width_o, binary_point_o, latency, overflow, quantization)
% This is a generated function based on subsystem:
%     untitled/convert_of0
% Though there are limitations about the generated script, 
% the main purpose of this utility is to make learning
% Sysgen Script easier.
% 
% To test it, run the following commands from MATLAB console:
% cfg.source = str2func('convert_of0');
% cfg.toplevel = 'untitled/convert_of0';
% args = {my_bit_width_i, my_binary_point_i, my_bit_width_o, my_binary_point_o, my_latency, my_overflow, my_quantization};
% xBlock(cfg, args);
% 
% You can edit convert_of0.m to debug your script.
% 
% You can also replace the MaskInitialization code with the 
% following commands so the subsystem will be generated 
% according to the values of mask parameters.
% cfg.source = str2func('convert_of0');
% cfg.toplevel = gcb;
% args = {bit_width_i, binary_point_i, bit_width_o, binary_point_o, latency, overflow, quantization};
% xBlock(cfg, args);
% 
% To configure the xBlock call in debug mode, in which mode,
% autolayout will be performed every time a block is added,
% run the following commands:
% cfg.source = str2func('convert_of0');
% cfg.toplevel = gcb;
% cfg.debug = 1;
% args = {bit_width_i, binary_point_i, bit_width_o, binary_point_o, latency, overflow, quantization};
% xBlock(cfg, args);
% 
% To make the xBlock smart so it won't re-generate the
% subsystem if neither the arguments nor the scripts are
% changes, use as the following:
% cfg.source = str2func('convert_of0');
% cfg.toplevel = gcb;
% cfg.depend = {'convert_of0'};
% args = {bit_width_i, binary_point_i, bit_width_o, binary_point_o, latency, overflow, quantization};
% xBlock(cfg, args);
% 
% See also xBlock, xInport, xOutport, xSignal, xlsub2script.


%% inports
xlsub2_din = xInport('din');

%% outports
xlsub2_dout = xOutport('dout');
xlsub2_of = xOutport('of');

%% diagram

% block: untitled/convert_of0/all_0s
xlsub2_invert1_out1 = xSignal;
xlsub2_invert2_out1 = xSignal;
xlsub2_all_0s_out1 = xSignal;
xlsub2_all_0s = xBlock(struct('source', 'Logical', 'name', 'all_0s'), ...
                       struct('logical_function', 'NAND', ...
                              'latency', latency), ...
                       {xlsub2_invert1_out1, xlsub2_invert2_out1}, ...
                       {xlsub2_all_0s_out1});

% block: untitled/convert_of0/all_1s
xlsub2_slice1_out1 = xSignal;
xlsub2_slice2_out1 = xSignal;
xlsub2_all_1s_out1 = xSignal;
xlsub2_all_1s = xBlock(struct('source', 'Logical', 'name', 'all_1s'), ...
                       struct('logical_function', 'NAND', ...
                              'latency', latency), ...
                       {xlsub2_slice1_out1, xlsub2_slice2_out1}, ...
                       {xlsub2_all_1s_out1});

% block: untitled/convert_of0/and
xlsub2_and = xBlock(struct('source', 'Logical', 'name', 'and'), ...
                    [], ...
                    {xlsub2_all_0s_out1, xlsub2_all_1s_out1}, ...
                    {xlsub2_of});

% block: untitled/convert_of0/convert
xlsub2_convert = xBlock(struct('source', 'Convert', 'name', 'convert'), ...
                        struct('n_bits', bit_width_o, ...
                               'bin_pt', binary_point_o, ...
                               'latency', latency, ...
                               'pipeline', 'on'), ...
                        {xlsub2_din}, ...
                        {xlsub2_dout});

% block: untitled/convert_of0/invert1
xlsub2_invert1 = xBlock(struct('source', 'Inverter', 'name', 'invert1'), ...
                        [], ...
                        {xlsub2_slice1_out1}, ...
                        {xlsub2_invert1_out1});

% block: untitled/convert_of0/invert2
xlsub2_invert2 = xBlock(struct('source', 'Inverter', 'name', 'invert2'), ...
                        [], ...
                        {xlsub2_slice2_out1}, ...
                        {xlsub2_invert2_out1});

% block: untitled/convert_of0/slice1
xlsub2_slice1 = xBlock(struct('source', 'Slice', 'name', 'slice1'), ...
                       struct('boolean_output', 'on'), ...
                       {xlsub2_din}, ...
                       {xlsub2_slice1_out1});

% block: untitled/convert_of0/slice2
xlsub2_slice2 = xBlock(struct('source', 'Slice', 'name', 'slice2'), ...
                       struct('boolean_output', 'on', ...
                              'bit1', -1), ...
                       {xlsub2_din}, ...
                       {xlsub2_slice2_out1});



end

