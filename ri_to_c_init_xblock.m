function ri_to_c01()
% This is a generated function based on subsystem:
%     untitled/butterfly_direct/ri_to_c01
% Though there are limitations about the generated script, 
% the main purpose of this utility is to make learning
% Sysgen Script easier.
% 
% To test it, run the following commands from MATLAB console:
% cfg.source = str2func('ri_to_c01');
% cfg.toplevel = 'untitled/butterfly_direct/ri_to_c01';
% args = {};
% xBlock(cfg, args);
% 
% You can edit ri_to_c01.m to debug your script.
% 
% You can also replace the MaskInitialization code with the 
% following commands so the subsystem will be generated 
% according to the values of mask parameters.
% cfg.source = str2func('ri_to_c01');
% cfg.toplevel = gcb;
% args = {};
% xBlock(cfg, args);
% 
% To configure the xBlock call in debug mode, in which mode,
% autolayout will be performed every time a block is added,
% run the following commands:
% cfg.source = str2func('ri_to_c01');
% cfg.toplevel = gcb;
% cfg.debug = 1;
% args = {};
% xBlock(cfg, args);
% 
% To make the xBlock smart so it won't re-generate the
% subsystem if neither the arguments nor the scripts are
% changes, use as the following:
% cfg.source = str2func('ri_to_c01');
% cfg.toplevel = gcb;
% cfg.depend = {'ri_to_c01'};
% args = {};
% xBlock(cfg, args);
% 
% See also xBlock, xInport, xOutport, xSignal, xlsub2script.


%% inports
xlsub3_re = xInport('re');
xlsub3_im = xInport('im');

%% outports
xlsub3_c = xOutport('c');

%% diagram

% block: untitled/butterfly_direct/ri_to_c01/concat
xlsub3_force_re_out1 = xSignal;
xlsub3_force_im_out1 = xSignal;
xlsub3_concat = xBlock(struct('source', 'Concat', 'name', 'concat'), ...
                       [], ...
                       {xlsub3_force_re_out1, xlsub3_force_im_out1}, ...
                       {xlsub3_c});

% block: untitled/butterfly_direct/ri_to_c01/force_im
xlsub3_force_im = xBlock(struct('source', 'Reinterpret', 'name', 'force_im'), ...
                         struct('force_arith_type', 'on', ...
                                'force_bin_pt', 'on'), ...
                         {xlsub3_im}, ...
                         {xlsub3_force_im_out1});

% block: untitled/butterfly_direct/ri_to_c01/force_re
xlsub3_force_re = xBlock(struct('source', 'Reinterpret', 'name', 'force_re'), ...
                         struct('force_arith_type', 'on', ...
                                'force_bin_pt', 'on'), ...
                         {xlsub3_re}, ...
                         {xlsub3_force_re_out1});



end

