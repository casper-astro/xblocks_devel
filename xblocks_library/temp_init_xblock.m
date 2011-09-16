function temp_init_xblock()
% This is a generated function based on subsystem:
%     untitled1/temp_init_xblock
% Though there are limitations about the generated script, 
% the main purpose of this utility is to make learning
% Sysgen Script easier.
% 
% To test it, run the following commands from MATLAB console:
% cfg.source = str2func('temp_init_xblock');
% cfg.toplevel = 'untitled1/temp_init_xblock';
% args = {};
% xBlock(cfg, args);
% 
% You can edit temp_init_xblock.m to debug your script.
% 
% You can also replace the MaskInitialization code with the 
% following commands so the subsystem will be generated 
% according to the values of mask parameters.
% cfg.source = str2func('temp_init_xblock');
% cfg.toplevel = gcb;
% args = {};
% xBlock(cfg, args);
% 
% To configure the xBlock call in debug mode, in which mode,
% autolayout will be performed every time a block is added,
% run the following commands:
% cfg.source = str2func('temp_init_xblock');
% cfg.toplevel = gcb;
% cfg.debug = 1;
% args = {};
% xBlock(cfg, args);
% 
% To make the xBlock smart so it won't re-generate the
% subsystem if neither the arguments nor the scripts are
% changes, use as the following:
% cfg.source = str2func('temp_init_xblock');
% cfg.toplevel = gcb;
% cfg.depend = {'temp_init_xblock'};
% args = {};
% xBlock(cfg, args);
% 
% See also xBlock, xInport, xOutport, xSignal, xlsub2script.


%% inports
xlsub2_din0 = xInport('din0');
xlsub2_en = xInport('en');
xlsub2_din1 = xInport('din1');

%% outports
xlsub2_dout = xOutport('dout');

%% diagram

% block: untitled1/temp_init_xblock/AddSub
xlsub2_AddSub = xBlock(struct('source', 'AddSub', 'name', 'AddSub'), ...
                       struct('en', 'on', ...
                              'latency', latency, ...
                              'precision', 'User Defined', ...
                              'n_bits', out_bit_width, ...
                              'bin_pt', in_bin_pt), ...
                       {xlsub2_din0, xlsub2_din1, xlsub2_en}, ...
                       {xlsub2_dout});



end

