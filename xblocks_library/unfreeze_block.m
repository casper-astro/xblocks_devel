function unfreeze_block(blk)
    init = get_param(blk, 'MaskInitialization');
    uncommented_init = regexprep(init, '%', '');
    set_param(blk, 'MaskInitialization', uncommented_init);
end