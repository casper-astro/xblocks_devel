function inputs = xblock_new_inputs( name, M, N )

inputs = {};
for m = 1:M
    for n = 1:N
        inputs{m,n} = xInput( [name, '_', num2str(M), '_', num2str(N)] );
    end
end

end

