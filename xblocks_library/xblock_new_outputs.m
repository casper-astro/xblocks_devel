function outputs = xblock_new_outputs( name, M, N )

outputs = {};
for m = 1:M
    for n = 1:N
        outputs{m,n} = xOutport( [name, '_', num2str(M), '_', num2str(N)] );
    end
end

end

