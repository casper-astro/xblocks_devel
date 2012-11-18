function run_init(blk)

masktype = get_param(blk, 'MaskType');
init_func_name = [masktype, '_init'];
disp(['Init function name is: ', init_func_name]);
[params,values] = get_mask_setting(blk);
init_func = str2func(init_func_name);
disp('Start running init function...');
init_func(blk, params{:})
disp('Done running init function!');
end