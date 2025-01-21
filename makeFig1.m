%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Script: cohenKappa_comparison.m
%
% Description:
%   1) Gathers the first 12 subfolders in the current directory.
%   2) In each subfolder, reads confusion matrices for:
%       - data_batch1_mini.csv
%       - data_batch2_mini.csv
%       - data_batch1_full.csv
%       - data_batch2_full.csv
%   3) Computes Cohen’s kappa for:
%       - Mini batch1 vs Mini batch2
%       - Full batch1 vs Full batch2
%       - Mini batch1 vs Full batch1
%       - Mini batch2 vs Full batch2
%   4) Displays the kappa results for each subfolder.
%
% Usage:
%   - Place this script in the parent directory containing the 12 subfolders.
%   - Ensure each subfolder contains the four required CSV files.
%   - Run the script in MATLAB.
%
% Note:
%   - Adjust the 'readConfMatrix' function if your CSV format differs.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clearvars
close all
clc

% Random seed for reproducibility (optional)
rng(12);

%% 1) Gather the first 12 subfolders
parentFolder = pwd;  % Current directory
folderList = dir(parentFolder);
folderList = folderList([folderList.isdir]);                  % Keep only directories
folderList = folderList(~ismember({folderList.name}, {'.','..'}));

if numel(folderList) < 12
    error('Need at least 12 subfolders in "%s".', parentFolder);
end

folderList = folderList(1:12);  % Select the first 12 subfolders

%% 2) Process each subfolder
for i = 1:numel(folderList)
    fprintf('\n=======================\n');
    fprintf('Processing folder %d of %d: %s\n', i, numel(folderList), folderList(i).name);
    fprintf('=======================\n');
    
    subFolderPath = fullfile(parentFolder, folderList(i).name);
    
    % Define file paths
    miniFile1 = fullfile(subFolderPath, 'data_batch1_mini.csv');
    miniFile2 = fullfile(subFolderPath, 'data_batch2_mini.csv');
    fullFile1 = fullfile(subFolderPath, 'data_batch1_full.csv');
    fullFile2 = fullfile(subFolderPath, 'data_batch2_full.csv');
    
    % Check if all required files exist
    requiredFiles = {miniFile1, miniFile2, fullFile1, fullFile2};
    missingFiles = requiredFiles(~cellfun(@(f) isfile(f), requiredFiles)));
    
    if ~isempty(missingFiles)
        warning('Missing files in folder "%s":\n%s', folderList(i).name, strjoin(missingFiles, '\n'));
        continue;  % Skip to the next folder
    end
    
    try
        % 2a) Read the mini confusion matrices for batch1 and batch2
        [miniRowLabels1, miniColLabels1, miniMat1] = readConfMatrix(miniFile1);
        [miniRowLabels2, miniColLabels2, miniMat2] = readConfMatrix(miniFile2);
        
        % Check row/col label consistency
        if ~isequal(miniRowLabels1, miniRowLabels2) || ~isequal(miniColLabels1, miniColLabels2)
            warning('Mini row/column labels differ between batch1 and batch2 in folder "%s"!', folderList(i).name);
        end
        
        % 2b) Read the full confusion matrices for batch1 and batch2
        [fullRowLabels1, fullColLabels1, fullMat1] = readConfMatrix(fullFile1);
        [fullRowLabels2, fullColLabels2, fullMat2] = readConfMatrix(fullFile2);
        
        % Check row/col label consistency
        if ~isequal(fullRowLabels1, fullRowLabels2) || ~isequal(fullColLabels1, fullColLabels2)
            warning('Full row/column labels differ between batch1 and batch2 in folder "%s"!', folderList(i).name);
        end
        
        % 3) Compute Cohen's kappa for each comparison
        kappaMini12    = computeCohensKappa(miniMat1, miniMat2);
        kappaFull12    = computeCohensKappa(fullMat1, fullMat2);
        kappaMiniFull1 = computeCohensKappa(miniMat1, fullMat1);
        kappaMiniFull2 = computeCohensKappa(miniMat2, fullMat2);
        
        % 4) Display results
        fprintf('Cohen''s kappa comparison in folder "%s":\n', folderList(i).name);
        fprintf('  Mini batch1 vs Mini batch2: %.4f\n', kappaMini12);
        fprintf('  Full batch1 vs Full batch2: %.4f\n', kappaFull12);
        fprintf('  Mini batch1 vs Full batch1: %.4f\n', kappaMiniFull1);
        fprintf('  Mini batch2 vs Full batch2: %.4f\n', kappaMiniFull2);
        
    catch ME
        fprintf('Error processing folder "%s": %s\n', folderList(i).name, ME.message);
    end
end

%% =========================================================================
%  HELPER FUNCTION: COHEN'S KAPPA
% =========================================================================
function kappa = computeCohensKappa(confMatrix1, confMatrix2)
    % Ensure both confusion matrices are the same size
    if ~isequal(size(confMatrix1), size(confMatrix2))
        error('Confusion matrices must have the same dimensions to compute kappa.');
    end
    
    % Flatten confusion matrices into vectors
    vec1 = confMatrix1(:);
    vec2 = confMatrix2(:);
    
    % Compute observed agreement
    observedAgreement = sum(vec1 == vec2) / numel(vec1);
    
    % Compute expected agreement
    total = sum(vec1) + sum(vec2);
    if total == 0
        error('Sum of confusion matrices is zero. Cannot compute expected agreement.');
    end
    prob1 = vec1 / total;
    prob2 = vec2 / total;
    expectedAgreement = sum(prob1 .* prob2);
    
    % Compute Cohen's kappa
    if (1 - expectedAgreement) == 0
        kappa = NaN;  % Undefined kappa
        warning('Expected agreement is 1. Kappa is undefined (set to NaN).');
    else
        kappa = (observedAgreement - expectedAgreement) / (1 - expectedAgreement);
    end
end

%% =========================================================================
%  HELPER FUNCTION: READ CONFUSION MATRIX
% =========================================================================
function [rowLabels, colLabels, confMatrix] = readConfMatrix(filename)
    % readConfMatrix:
    %   Reads a CSV file containing a confusion matrix with row and column labels.
    %
    %   Assumes:
    %     - First row contains column labels (starting from second column).
    %     - First column contains row labels (starting from second row).
    %     - Top-left cell (1,1) is ignored or can be a placeholder.
    %     - The confusion matrix is numeric and starts from (2,2).
    %
    %   Outputs:
    %     - rowLabels: Cell array or numeric array of row labels.
    %     - colLabels: Cell array or numeric array of column labels.
    %     - confMatrix: Numeric 12x12 confusion matrix.
    %
    % Example CSV Structure:
    %       ,Cat1,Cat2,...,Cat12
    %   Cat1, 10,  1, ...,   0
    %   Cat2,  2, 15, ...,   1
    %   ...
    %   Cat12, 0,  1, ...,  12
    
    % Check if file exists
    if ~isfile(filename)
        error('File "%s" does not exist.', filename);
    end
    
    % Read the CSV file as a table without variable names
    opts = detectImportOptions(filename, 'NumHeaderLines', 0, 'ReadVariableNames', false);
    rawData = readtable(filename, opts);
    
    % Validate the size of the table
    expectedSize = [13, 13];  % 1 header row + 12 data rows, 1 header column + 12 data columns
    if size(rawData,1) ~= 13 || size(rawData,2) ~= 13
        error('Unexpected size for confusion matrix in file "%s". Expected 13x13 (including labels), got %dx%d.', filename, size(rawData,1), size(rawData,2));
    end
    
    % Extract column labels (from the first row, excluding the first cell)
    colLabels = rawData{1, 2:end};
    
    % Extract row labels (from the first column, excluding the first cell)
    rowLabels = rawData{2:end, 1};
    
    % Extract the confusion matrix (from row 2:end, column 2:end)
    confMatrix = rawData{2:end, 2:end};
    
    % Validate that the confusion matrix is numeric
    if ~all(all(isnumeric(confMatrix)))
        error('Confusion matrix in file "%s" contains non-numeric data.', filename);
    end
    
    % Optionally, convert labels to strings if they are not already
    if iscell(rowLabels)
        rowLabels = string(rowLabels);
    end
    if iscell(colLabels)
        colLabels = string(colLabels);
    end
end
