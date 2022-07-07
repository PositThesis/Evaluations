size_ = 20

A_ = dlmread("inputs/complex20A.mtx", " ", 2, 0);
B_ = dlmread("inputs/complex20B.mtx", " ", 2, 0);
C_ = dlmread("inputs/complex20C.mtx", " ", 2, 0);

A = zeros(size_);
B = zeros(size_);
C = zeros(size_);

for idx = 1 : rows(A_)
    row = A_(idx, :);
    x = row(1);
    y = row(2);
    if (x <= size_ && y <= size_)
        val_r = row(3);
        val_i = row(4);
        A(x, y) = val_r + val_i * i;
    endif
endfor
for idx = 1 : rows(B_)
    row = B_(idx, :);
    x = row(1);
    y = row(2);
    if (x <= size_ && y <= size_)
        val_r = row(3);
        val_i = row(4);
        B(x, y) = val_r + val_i * i;
    endif
endfor
for idx = 1 : rows(C_)
    row = C_(idx, :);
    x = row(1);
    y = row(2);
    if (x <= size_ && y <= size_)
        val_r = row(3);
        val_i = row(4);
        C(x, y) = val_r + val_i * i;
    endif
endfor

A
B
C
eigens = polyeig(A, B, C);


for idx = 1 : rows(eigens)
    eigen = eigens(idx);
    if (abs(eigen) <= 1.0)
      eigen
    endif
endfor

fid = fopen('octave_eigs.mtx', 'w+');
fprintf(fid, '# octave solution for the eigenvalues of A + z*B + z*z*C\n');
fprintf(fid, '%d %d %d\n', size(eigens, 1), size(eigens, 2), size(eigens, 1) * size(eigens, 2));
for i=1:size(eigens, 1)
    for j=1:size(eigens, 2)
        fprintf(fid, '%d %d %f %f\n', i, j, real(eigens(i, j)), imag(eigens(i, j)));
    endfor
endfor
fclose(fid);