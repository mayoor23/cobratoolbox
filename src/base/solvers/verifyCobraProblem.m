function [statusOK, invalidConstraints, invalidVars, objective] = verifyCobraProblem(XPproblem, x, tol, verbose)
% Verifies dimensions of fields in `XPproblem` and determines if they are
% valid LP, QP, MILP, MIQP problems. Also checks inputs for NaN.
% If `x` is provided, it will see if `x` is a valid solution to tolerance (tol).
%
% USAGE:
%
%    [statusOK, invalidConstraints, invalidVars, objective] = verifyCobraProblem(XPproblem, x, tol, verbose)
%
% INPUT:
%    XPproblem:             struct containing:
%
%                             * .A - Constraints matrix
%                             * .b - rhs
%                             * .csense - vector of 'E', 'L', 'G' for equality, Less than and Greater than constraint
%                             * .lb, .ub - lower and upper bound on variables
%                             * .c - objective coefficients
%                             * .F - quadratic objective (optional, only used for QP, MIQP problems)
%                             * .vartype - vector of 'C', 'I', 'B' for 'continuous', 'integer', 'binary'
%                               variables (optional, only used for MILP, MIQP problems).
%
% OPTIONAL INPUT:
%    x:                     Vector. Function will determine if `x` satisfies `XPproblem`
%    tol:                   numerical tolerance to which all constraints should be verified to. (default = 1e-8)
%    verbose:               Controls whether results are printed to screen.(Default = true)
%
% OUTPUT:
%    statusOK:              Returns -1 if any field in `XPproblem` has an error,
%                           returns 0 if the x vector is not valid for `XPproblem` and
%                           returns 1 if at least one problem type is satisfied
%    invalidConstraints:    Vector which lists a 1 for any constaint that is invalid
%    invalidVars:           Vector which lists a 1 for any variable that is invalid
%    objective:             Objective of `XPproblem`
%
% .. Authors: - Jan Shellenberger (11/23/09), Richard Que (11/24/09)

if nargin < 3
    tol = 1e-8;
end
if nargin < 4
    verbose = true;
end


validQP = false;
validMI = false;
objective = [];
statusOK = 1;

%Check A
if ~isfield(XPproblem, 'A')
    warning('Required field A not found');
    statusOK = -1;
    return;
elseif any(isnan(XPproblem.A(:)))
    [r c] = find(isnan(XPproblem.A));
    strCoords = '';
    for i=1:length(r)
        strCoords = [strCoords ' ' num2str(r(i)) ',' num2str(c(i))];
    end
    warning(['NaN present in A matrix at' strCoords '.']);
    statusOK = -1;
    return;
end
[nconstraints, nvars] = size(XPproblem.A);


%Check b
if ~isfield(XPproblem, 'b')
    warning('Required field b not found');
    statusOK = -1;
    return;
elseif any(isnan(XPproblem.b))
    r= find(isnan(XPproblem.b));
    strCoords = '';
    for i=1:length(r)
        strCoords = [strCoords ' ' num2str(r(i)) ','];
    end
    warning(['NaN present in b vector at' strCoords '.']);
    statusOK = -1;
    return;
elseif ~isnumeric(XPproblem.b)
    warning('b must be numeric')
    statusOK = -1;
    return
end
if any(size(XPproblem.b) ~= [nconstraints, 1])
    warning('Wrong size b vector');
    statusOK = -1;
    return;
end

%Check csense
if ~isfield(XPproblem, 'csense')
    warning('Required field csense not found');
    statusOK = -1;
    return;
end
if length(XPproblem.csense) ~= nconstraints
    if isfield(XPproblem,'dsense')
        if length(XPproblem.csense)+length(XPproblem.dsense) ~= nconstraints
            warning('Wrong size dsense vector...');
            fprintf('%s\n',['dsense dimensions:         ' num2str(length(XPproblem.dsense))])
            fprintf('%s\n',['csense dimensions:         ' num2str(length(XPproblem.csense))])
            fprintf('%s\n',[' sum sense dimensions:     ' num2str(length(XPproblem.csense)+length(XPproblem.dsense))])
            fprintf('%s\n',['constraint dimensions:     ' num2str(nconstraints)])
            statusOK = -1;
            return;
        end
    else
        warning('Wrong size csense vector...');
        fprintf('%s\n',['csense dimensions:         ' num2str(length(XPproblem.csense))])
        fprintf('%s\n',['constraint dimensions:     ' num2str(num2str(nconstraints))])
        statusOK = -1;
        return;
    end
end
if size(XPproblem.csense,2) ~= 1
    warning('Csense should be a column vector')
    statusOK = -1;
    return;
end
invalidCsense = find(~ismember(XPproblem.csense,['E','L','G']));
if invalidCsense
    warning('Invalid csense entry(s) at %s', num2str(invalidCsense));
    statusOK = -1;
    return;
end

%check lb
if ~isfield(XPproblem,'lb')
    warning('Required field lb not found');
    statusOK = -1;
    return;
elseif any(isnan(XPproblem.lb))
    r= find(isnan(XPproblem.lb));
    strCoords = '';
    for i=1:length(r)
        strCoords = [strCoords ' ' num2str(r(i)) ','];
    end
    warning(['NaN present in lb vector at' strCoords '.']);
    statusOK = -1;
    return;
elseif ~isnumeric(XPproblem.lb)
    warning('lb must be numeric')
    statusOK = -1;
    return
end
if any(size(XPproblem.lb) ~= [nvars, 1])
    warning('Wrong size lb vector');
    statusOK = -1;
    return;
end

%check ub
if ~isfield(XPproblem,'ub')
    warning('Required field ub not found');
    statusOK = -1;
    return;
elseif any(isnan(XPproblem.ub))
    r= find(isnan(XPproblem.ub));
    strCoords = '';
    for i=1:length(r)
        strCoords = [strCoords ' ' num2str(r(i)) ','];
    end
    warning(['NaN present in ub vector at' strCoords '.']);
    statusOK = -1;
    return;
elseif ~isnumeric(XPproblem.ub)
    warning('ub must be numeric')
    statusOK = -1;
    return
end
if any(size(XPproblem.ub) ~= [nvars, 1])
    warning('Wrong size ub vector');
    statusOK = -1;
    return;
end

if any(XPproblem.ub<XPproblem.lb)
    warning('Upper bound less than lower bound (ub<lb) at %s', num2str(find(XPproblem.ub<XPproblem.lb)));
    statusOK = -1;
    return;
end

%check c
if ~isfield(XPproblem,'c')
    warning('Required field c not found');
    statusOK = -1;
    return;
elseif any(isnan(XPproblem.c))
    r= find(isnan(XPproblem.c));
    strCoords = '';
    for i=1:length(r)
        strCoords = [strCoords ' ' num2str(r(i)) ','];
    end
    warning(['NaN present in c vector at' strCoords '.']);
    statusOK = -1;
    return;
elseif ~isnumeric(XPproblem.c)
    warning('c must be numeric')
    statusOK = -1;
    return
end
if any(size(XPproblem.c) ~= [nvars, 1])
    warning('Wrong size c vector');
    statusOK = -1;
    return;
end

validLP = true;

if isfield(XPproblem,'F')
    [nRows nCols] = size(XPproblem.F);
    if any(isnan(XPproblem.F(:)))
        [r c]= find(isnan(XPproblem.F));
        strCoords = '';
        for i=1:length(r)
            strCoords = [strCoords ' ' num2str(r(i)) ',' num2str(c(i))];
        end
        warning(['NaN present in F matrix at' strCoords '.']);
        statusOK = -1;
        return;
    elseif ~isnumeric(XPproblem.F)
        warning('F must be numeric')
        statusOK = -1;
        return
    end
    if nRows ~= nCols
        warning('F matrix not square');
        statusOK = -1;
    elseif nRows ~= nvars
        warning('Wrong size F matrix');
        statusOK = -1;
    else
        validQP = true;
    end
end

if isfield(XPproblem,'vartype')
    if all(size(XPproblem.vartype) == [nvars,1])
        invalidVartype = find(~ismember(XPproblem.vartype,['C','I','B']));
        if isempty(invalidVartype)
            validMI = true;
        else
            warning('Invalid vartype entry(s) at %s', num2str(invalidVartype));
            statusOK = -1;
        end
    else
        warning('Wrong size vartype vector');
        statusOK = -1;
    end
    vartype = XPproblem.vartype;
    if any(floor(XPproblem.ub(vartype == 'I' | vartype == 'B') + tol) < ceil(XPproblem.lb(vartype =='I' | vartype == 'B') - tol))
        warning('Integer or binary variables lb to ub range does not contain an integer');
        validMI = false;
        statusOK = -1;
    end
    if any(XPproblem.lb(vartype == 'B') ~= 0)
        warning('Binary variables have lower bound not equal to zero.  This is inconsistent');
        validMI = false;
        statusOK = -1;
    end
    if any(XPproblem.ub(vartype == 'B') ~= 1)
        warning('Binary variables have upper bound not equal to one.  This is inconsistent');
        validMI=false;
        statusOK = -1;
    end
end

if verbose
    if validLP
        display('Valid LP problem');
    else
        display('Invalid LP problem');
    end
    if validMI && validLP
        display('Valid MILP problem');
    else
        display('Invalid MILP problem');
    end
    if validQP
        display('Valid QP problem');
    else
        display('Invalid QP problem');
    end
    if validMI && validQP
        display('Valid MIQP problem');
    else
        display('Invalid MIQP problem');
    end
    if ~validLP&&~validQP
        return;
    end
end

%check x vector if present
if nargin >= 2 && ~isempty(x)
    validX = true;
    validXMI = false;
    if any(size(x)~=[nvars,1])
        warning('Wrong size x vector');
        statusOK = 0;
        return;
    end
    if any(isnan(x))
    r= find(isnan(x));
    strCoords = '';
    for i=1:length(r)
        strCoords = [strCoords ' ' num2str(r(i)) ','];
    end
    warning(['NaN present in x vector at' strCoords '.']);
    statusOK = -1;
    return;
    end
    invalidConstraints = zeros(nconstraints,1);
    invalidVars = zeros(nvars,1);
    if any(x > XPproblem.ub + tol)
        invalidVars(x > XPproblem.ub + tol) = 1;
        warning('Upper bound violation')
        statusOK = 0;
    end
    if any(x < XPproblem.lb - tol)
        invalidVars(x < XPproblem.lb - tol) = 1;
        warning('Lower bound violation')
        statusOK = 0;
    end
    product = XPproblem.A*x;

    if any(abs(product(XPproblem.csense == 'E') - XPproblem.b(XPproblem.csense == 'E')) > tol)
        invalidConstraints(abs(product(XPproblem.csense == 'E') - XPproblem.b(XPproblem.csense == 'E')) > tol) = 1;
        warning('Equality constraint off');
        validX = false;
        statusOK = 0;
    end
    if any(product(XPproblem.csense == 'L') > XPproblem.b(XPproblem.csense == 'L') + tol)
        invalidConstraints(product(XPproblem.csense == 'L') > XPproblem.b(XPproblem.csense == 'L') + tol) = 1;
        warning('L constraint off');
        validX = false;
        statusOK = 0;
    end
    if any(product(XPproblem.csense == 'G') < XPproblem.b(XPproblem.csense == 'G') - tol)
        invalidConstraints(product(XPproblem.csense == 'G') < XPproblem.b(XPproblem.csense == 'G') - tol) = 1;
        warning('G constraint off');
        validX = false;
        statusOK = 0;
    end

    % MI constraints
    if isfield(XPproblem, 'vartype')
        validXMI = true;
        if(abs( x(vartype == 'I' | vartype == 'B') - round(x(vartype == 'I' | vartype == 'B'))) > tol)
            warning('Integer constraint off')
            validXMI = false;
            statusOK = 0;
        end
    end
    if validX
        if validXMI
            display('Valid x vector for MIXP problem');
        else
            display('Valid x vector for XP problem');
        end
    end
    %objective
    if validQP
        objective = (1/2)*x'*XPproblem.F*x + XPproblem.c'*x;
    elseif validLP
        objective = XPproblem.c'*x;
    end
    invalidConstraints = find(invalidConstraints);
    invalidVars = find(invalidVars);
end
