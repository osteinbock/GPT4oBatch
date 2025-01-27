% Script: makeFig2.m
% 01/19/25 Figure 2 for Deven Dangi's GPT Paper
%
% Reads four CSV files:
%   data_batch1_mini.csv
%   data_batch2_mini.csv
%   data_batch1_full.csv
%   data_batch2_full.csv
%
% Sums the "mini" pair and the "full" pair separately.
% Plots each sum in its own figure, using reversed 'hot' colormap with caxis [0..200].
% If cell value >= 50, overlay text in white; otherwise black.
% Axis labels & colorbar label = bold; tick labels & cell text = normal.
% The colorbar label is given the same font size as the axis labels.
% Each figure is saved as fig2a.jpg or fig2b.jpg, at 300 dpi.

clearvars
close all

%% 1) READ AND SUM "MINI" DATA
[miniRowLabels, miniColLabels, miniMat1] = readConfMatrix('data_batch1_mini.csv');
[miniRowLabels2, miniColLabels2, miniMat2] = readConfMatrix('data_batch2_mini.csv');

if ~isequal(miniRowLabels, miniRowLabels2) || ~isequal(miniColLabels, miniColLabels2)
    warning('Mini row/column labels differ between batch1 and batch2!');
end

confMatrixMini = miniMat1 + miniMat2;

%% 2) READ AND SUM "FULL" DATA
[fullRowLabels, fullColLabels, fullMat1] = readConfMatrix('data_batch1_full.csv');
[fullRowLabels2, fullColLabels2, fullMat2] = readConfMatrix('data_batch2_full.csv');

if ~isequal(fullRowLabels, fullRowLabels2) || ~isequal(fullColLabels, fullColLabels2)
    warning('Full row/column labels differ between batch1 and batch2!');
end

confMatrixFull = fullMat1 + fullMat2;

%% 3) PLOT AND SAVE MINI (fig2a.jpg)
fMini = plotConfMatrix(confMatrixMini, miniRowLabels, miniColLabels);
exportgraphics(fMini, 'fig2a.jpg', 'Resolution', 300);

%% 4) PLOT AND SAVE FULL (fig2b.jpg)
fFull = plotConfMatrix(confMatrixFull, fullRowLabels, fullColLabels);
exportgraphics(fFull, 'fig2b.jpg', 'Resolution', 300);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% HELPER FUNCTIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [rowLabels, colLabels, confMatrix] = readConfMatrix(csvFile)
    % Reads a CSV file with:
    %   1st row => column labels (skip top-left cell)
    %   1st col => row labels (skip header)
    %   The rest => numeric confusion matrix

    rawData = readcell(csvFile);

    colLabels = rawData(1, 2:end);
    rowLabels = rawData(2:end, 1);

    confMatrixCells = rawData(2:end, 2:end);
    confMatrix = cellfun(@(x) str2double(string(x)), confMatrixCells);
end

function fig = plotConfMatrix(confMat, rowLabels, colLabels)
    % Creates a new figure with imagesc, reversed 'hot' [0..200].
    % Cell >= 50 => white text; else black. 
    % Axis labels & colorbar label = bold, same font size. 
    % Tick labels & cell text = normal.
    % Returns the figure handle so we can exportgraphics().

    fig = figure('Color','w','Position',[100 100 600 600]);

    % Plot the matrix
    imagesc(confMat);

    % Reverse 'hot' => 0 is white
    colormap(flipud(hot));

    % Force color limits [0..200]
    caxis([0 200]);

    % Add colorbar
    cb = colorbar;
    cb.Label.String = 'Count';
    cb.Label.FontWeight = 'bold';

    axis square;

    % Ticks & labels
    numRows = size(confMat,1);
    numCols = size(confMat,2);

    % X axis ticks
    set(gca, 'XTick', 1:numCols, 'XTickLabel', colLabels, ...
             'FontWeight','normal');
    % Y axis ticks
    set(gca, 'YTick', 1:numRows, 'YTickLabel', rowLabels, ...
             'FontWeight','normal');

    % Axis labels in bold
    xlabel('Predicted Labels','FontWeight','bold');
    ylabel('True Labels','FontWeight','bold');

    % Match colorbar label font size to axis label size
    ax = gca;  
    cb.Label.FontSize = ax.XLabel.FontSize;

    % Overlay integer values
    for r = 1:numRows
        for c = 1:numCols
            val = confMat(r,c);
            valStr = sprintf('%d', val);
            if val >= 50
                textColor = 'white';
            else
                textColor = 'black';
            end
            text(c, r, valStr, ...
                'Color', textColor, ...
                'HorizontalAlignment','center', ...
                'VerticalAlignment','middle', ...
                'FontWeight','normal'); 
        end
    end

end
