function freeze_block(blk)
    init = get_param(blk, 'MaskInitialization');
    commented_init = strcat('%', regexprep(init, '\n', '\n%'));
    set_param(blk, 'MaskInitialization', commented_init);
end