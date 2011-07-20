function distance = mcdmahal (Y,X)
[m n]=size(Y);
[res raw]=fastmcdNoPlot(X);
for i=1:m
    distance(i)=(Y(i,:)-res.center)*inv(res.cov)*(Y(i,:)-res.center)';
end