%% LTE RADIO NETWORK PLANNING
% Educational downlink system-level simulation.
% Uses base MATLAB only.
%
% Models:
%   - Hexagonal site deployment
%   - Urban macrocell path loss at 2 GHz
%   - Omni and three-sector antennas
%   - Site-level frequency reuse: 1, 3, 7
%   - Full-load co-channel interference
%   - Received power, SINR, coverage, and rate proxy
%
% Important:
% Received power here is integrated serving-cell received power,
% NOT LTE RSRP.
% Rate is a Shannon-based proxy, NOT measured LTE throughput.

clear;
clc;
close all;

%% 1. Configuration
cfg.fcMHz = 2000;
cfg.sitePower_dBm = 46;       % Total conducted power per site
cfg.noiseFigure_dB = 7;
cfg.temperature_K = 290;

cfg.totalRB = 50;             % Nominal 10 MHz LTE carrier
cfg.rbBandwidth_Hz = 180e3;

cfg.sectorPeakGain_dBi = 15;
cfg.omniGain_dBi = 0;
cfg.beamwidth_deg = 65;
cfg.maxAttenuation_dB = 20;

cfg.minDistance_m = 35;
cfg.minCouplingLoss_dB = 70;

cfg.rxThreshold_dBm = -100;
cfg.sinrThreshold_dB = -3;

cfg.tiers = 2;               % Two rings -> 19 sites
cfg.gridSize = 181;

cfg.isdValues_m = [500 750 1000];
cfg.sectorValues = [1 3];
cfg.reuseValues = [1 3 7];

cfg.outputFolder = 'results';

if ~exist(cfg.outputFolder, 'dir')
    mkdir(cfg.outputFolder);
end

%% 2. Run planning scenarios
% Results are evaluated over the central site's nominal hexagon.
% Surrounding sites act as interferers and possible serving cells.

rows = [];
reference = [];
referenceSites = [];

for isd = cfg.isdValues_m

    [sites, axial] = createSites(cfg.tiers, isd);

    extent = (cfg.tiers + 0.75) * isd;
    axisVector = linspace(-extent, extent, cfg.gridSize);
    [X, Y] = meshgrid(axisVector, axisVector);

    % Central Voronoi hexagon of the triangular site lattice
    cellRadius = isd / sqrt(3);
    hexAngles = 30:60:390;

    hexX = cellRadius * cosd(hexAngles);
    hexY = cellRadius * sind(hexAngles);

    evaluationMask = inpolygon(X, Y, hexX, hexY);

    for sectors = cfg.sectorValues
        for reuse = cfg.reuseValues

            result = simulateScenario( ...
                cfg, sites, axial, X, Y, sectors, reuse);

            sinrSamples = result.sinr_dB(evaluationMask);
            rateSamples = result.rateProxy_Mbps(evaluationMask);
            coverageSamples = result.covered(evaluationMask);

            sortedRates = sort(rateSamples);
            p5Index = max(1, ceil(0.05 * numel(sortedRates)));

            % Hexagonal site area = sqrt(3)/2 * ISD^2
            siteDensity = 1e6 / ((sqrt(3)/2) * isd^2);

            rows(end+1, :) = [ ...
                isd, ...
                sectors, ...
                reuse, ...
                size(sites, 1), ...
                siteDensity, ...
                result.rbPerCell, ...
                result.unassignedRB, ...
                100 * mean(coverageSamples), ...
                mean(sinrSamples), ...
                mean(rateSamples), ...
                sortedRates(p5Index) ...
            ]; %#ok<SAGROW>

            % Save one representative map scenario
            if isd == 750 && sectors == 3 && reuse == 1
                reference = result;
                reference.X = X;
                reference.Y = Y;
                reference.evaluationMask = evaluationMask;
                reference.hexX = hexX;
                reference.hexY = hexY;
                referenceSites = sites;
            end
        end
    end
end

%% 3. Export planning results
summary = array2table(rows, 'VariableNames', { ...
    'ISD_m', ...
    'SectorsPerSite', ...
    'ReuseFactor', ...
    'NumberOfSites', ...
    'SiteDensity_per_km2', ...
    'RB_PerCell', ...
    'UnassignedRB', ...
    'Coverage_percent', ...
    'MeanSINR_dB', ...
    'MeanRateProxy_Mbps', ...
    'P5RateProxy_Mbps'});

disp(summary);

writetable(summary, ...
    fullfile(cfg.outputFolder, 'scenario_summary.csv'));

save(fullfile(cfg.outputFolder, 'planning_results.mat'), ...
    'cfg', 'summary', 'reference', 'referenceSites');

%% 4. Base-station deployment plot
f1 = figure('Color', 'w', 'Name', 'Base-station deployment');

hold on;

isd = 750;
cellRadius = isd / sqrt(3);
hexAngles = 30:60:390;

for n = 1:size(referenceSites, 1)

    hx = referenceSites(n,1) + cellRadius * cosd(hexAngles);
    hy = referenceSites(n,2) + cellRadius * sind(hexAngles);

    plot(hx, hy, 'Color', [0.65 0.65 0.65]);

    plot(referenceSites(n,1), referenceSites(n,2), ...
        'k^', 'MarkerFaceColor', 'k');

    text(referenceSites(n,1)+25, referenceSites(n,2)+25, ...
        sprintf('%d', n));

    for azimuth = [0 120 240]
        quiver(referenceSites(n,1), referenceSites(n,2), ...
            0.25*isd*cosd(azimuth), ...
            0.25*isd*sind(azimuth), ...
            0, 'r', 'LineWidth', 1);
    end
end

plot(reference.hexX, reference.hexY, 'b-', 'LineWidth', 2);

axis equal;
grid on;
xlabel('X position (m)');
ylabel('Y position (m)');
title('19-site deployment: ISD = 750 m');
hold off;

saveas(f1, fullfile(cfg.outputFolder, 'deployment.png'));

%% 5. Coverage, interference, and cell-distribution maps
f2 = figure('Color', 'w', 'Name', 'Radio planning maps');

subplot(2,2,1);
drawMap(reference, reference.rx_dBm, referenceSites, ...
    'Serving-cell received power (dBm)');

subplot(2,2,2);
drawMap(reference, reference.sinr_dB, referenceSites, ...
    'SINR (dB)');

subplot(2,2,3);
drawMap(reference, reference.servingCell, referenceSites, ...
    'Serving-cell ID');

subplot(2,2,4);
drawMap(reference, double(reference.covered), referenceSites, ...
    'Coverage: 1 = covered, 0 = outage');
caxis([0 1]);

saveas(f2, fullfile(cfg.outputFolder, 'radio_maps.png'));

%% 6. Compare planning scenarios
f3 = figure('Color', 'w', 'Name', 'Scenario comparisons');

metricNames = { ...
    'Coverage_percent', ...
    'MeanSINR_dB', ...
    'MeanRateProxy_Mbps'};

metricLabels = { ...
    'Coverage (%)', ...
    'Mean SINR (dB)', ...
    'Mean rate proxy (Mbps)'};

for panel = 1:3

    subplot(1,3,panel);
    hold on;

    labels = {};

    for sectors = cfg.sectorValues
        for reuse = cfg.reuseValues

            selected = ...
                summary.SectorsPerSite == sectors & ...
                summary.ReuseFactor == reuse;

            plot(summary.ISD_m(selected), ...
                summary.(metricNames{panel})(selected), ...
                '-o', 'LineWidth', 1.5);

            labels{end+1} = sprintf('%d sector(s), reuse %d', ...
                sectors, reuse); %#ok<SAGROW>
        end
    end

    grid on;
    xlabel('Inter-site distance (m)');
    ylabel(metricLabels{panel});
    title(metricLabels{panel});

    if panel == 1
        legend(labels, 'Location', 'best');
    end

    hold off;
end

saveas(f3, fullfile(cfg.outputFolder, 'scenario_comparison.png'));

%% 7. Path-loss curve
distance_m = logspace(log10(35), log10(5000), 200);

macroPL = 128.1 + 37.6*log10(distance_m/1000);

freeSpacePL = 32.45 + 20*log10(cfg.fcMHz) + ...
    20*log10(distance_m/1000);

appliedPL = max(macroPL, freeSpacePL);

f4 = figure('Color', 'w', 'Name', 'Propagation model');

semilogx(distance_m, macroPL, '--', 'LineWidth', 1.5);
hold on;
semilogx(distance_m, freeSpacePL, ':', 'LineWidth', 1.5);
semilogx(distance_m, appliedPL, '-', 'LineWidth', 2);

grid on;
xlabel('Distance (m)');
ylabel('Path loss (dB)');
title('Propagation at 2 GHz');
legend('Urban macro model', 'Free-space floor', ...
    'Applied path loss', 'Location', 'best');

saveas(f4, fullfile(cfg.outputFolder, 'path_loss.png'));

fprintf('\nSimulation complete. Outputs saved in "%s".\n', ...
    cfg.outputFolder);

%% LOCAL FUNCTIONS

function [sites, axial] = createSites(tiers, isd)
% Triangular lattice with a hexagonal boundary.

    axial = [];

    for q = -tiers:tiers
        for r = -tiers:tiers
            if max(abs([q r q+r])) <= tiers
                axial(end+1,:) = [q r]; %#ok<AGROW>
            end
        end
    end

    sites = [ ...
        isd * (axial(:,1) + axial(:,2)/2), ...
        isd * (sqrt(3)/2) * axial(:,2) ...
    ];
end

function group = assignReuseGroups(axial, reuse)
% Site-level frequency coloring.
% All sectors at a site share that site's resource-block group.

    q = axial(:,1);
    r = axial(:,2);

    switch reuse
        case 1
            group = ones(size(q));
        case 3
            group = mod(q-r, 3) + 1;
        case 7
            group = mod(q+3*r, 7) + 1;
        otherwise
            error('Supported reuse factors are 1, 3, and 7.');
    end
end

function out = simulateScenario(cfg, sites, axial, X, Y, ...
    sectors, reuse)

    numberOfSites = size(sites,1);
    numberOfCells = numberOfSites * sectors;

    userX = X(:);
    userY = Y(:);
    numberOfPoints = numel(userX);

    siteGroups = assignReuseGroups(axial, reuse);

    rbPerCell = floor(cfg.totalRB / reuse);
    occupiedBandwidth = rbPerCell * cfg.rbBandwidth_Hz;

    % Fixed total site power across all scenarios.
    % Split conducted power equally among sectors.
    cellPower_dBm = cfg.sitePower_dBm - 10*log10(sectors);

    receivedPower_dBm = zeros(numberOfPoints, numberOfCells);
    cellGroups = zeros(1, numberOfCells);

    cellIndex = 0;

    for siteIndex = 1:numberOfSites

        dx = userX - sites(siteIndex,1);
        dy = userY - sites(siteIndex,2);

        distance_m = max(hypot(dx,dy), cfg.minDistance_m);
        distance_km = distance_m / 1000;

        macroPL = 128.1 + 37.6*log10(distance_km);

        freeSpacePL = 32.45 + 20*log10(cfg.fcMHz) + ...
            20*log10(distance_km);

        pathLoss_dB = max(macroPL, freeSpacePL);
        bearing_deg = atan2d(dy,dx);

        for sectorIndex = 1:sectors

            cellIndex = cellIndex + 1;

            if sectors == 1
                antennaGain_dBi = ...
                    cfg.omniGain_dBi * ones(numberOfPoints,1);
            else
                boresight = (sectorIndex-1) * 360/sectors;

                angleOffset = ...
                    mod(bearing_deg-boresight+180,360)-180;

                attenuation_dB = min( ...
                    12*(angleOffset/cfg.beamwidth_deg).^2, ...
                    cfg.maxAttenuation_dB);

                antennaGain_dBi = ...
                    cfg.sectorPeakGain_dBi - attenuation_dB;
            end

            couplingLoss_dB = max( ...
                pathLoss_dB - antennaGain_dBi, ...
                cfg.minCouplingLoss_dB);

            receivedPower_dBm(:,cellIndex) = ...
                cellPower_dBm - couplingLoss_dB;

            cellGroups(cellIndex) = siteGroups(siteIndex);
        end
    end

    %% Serving-cell association: strongest received power
    [servingPower_dBm, servingCell] = ...
        max(receivedPower_dBm, [], 2);

    receivedPower_mW = 10.^(receivedPower_dBm/10);
    servingPower_mW = 10.^(servingPower_dBm/10);

    servingGroup = reshape(cellGroups(servingCell), [], 1);

    %% Full-load interference from cells using the same RB group
    interference_mW = zeros(numberOfPoints,1);

    for groupIndex = 1:reuse

        groupTotalPower = sum( ...
            receivedPower_mW(:,cellGroups == groupIndex), 2);

        selectedPoints = servingGroup == groupIndex;

        interference_mW(selectedPoints) = ...
            groupTotalPower(selectedPoints) - ...
            servingPower_mW(selectedPoints);
    end

    interference_mW = max(interference_mW,0);

    %% Receiver thermal noise: k*T*B with receiver noise figure
    boltzmann = 1.380649e-23;

    noise_W = boltzmann * cfg.temperature_K * ...
        occupiedBandwidth * 10^(cfg.noiseFigure_dB/10);

    noise_mW = 1000 * noise_W;

    sinrLinear = servingPower_mW ./ ...
        (interference_mW + noise_mW);

    sinr_dB = 10*log10(sinrLinear);

    %% Coverage and idealized rate proxy
    covered = ...
        servingPower_dBm >= cfg.rxThreshold_dBm & ...
        sinr_dB >= cfg.sinrThreshold_dB;

    rateProxy_Mbps = ...
        occupiedBandwidth * log2(1+sinrLinear) / 1e6;

    % No service is assumed at points failing coverage criteria.
    rateProxy_Mbps(~covered) = 0;

    out.rx_dBm = reshape(servingPower_dBm, size(X));
    out.sinr_dB = reshape(sinr_dB, size(X));
    out.servingCell = reshape(servingCell, size(X));
    out.covered = reshape(covered, size(X));
    out.rateProxy_Mbps = reshape(rateProxy_Mbps, size(X));

    out.rbPerCell = rbPerCell;
    out.unassignedRB = cfg.totalRB - reuse*rbPerCell;
end

function drawMap(reference, values, sites, titleText)

    imagesc(reference.X(1,:), reference.Y(:,1), values);
    set(gca, 'YDir', 'normal');

    axis equal tight;
    colorbar;
    hold on;

    plot(sites(:,1), sites(:,2), ...
        'k^', 'MarkerFaceColor', 'w', 'MarkerSize', 5);

    plot(reference.hexX, reference.hexY, ...
        'w-', 'LineWidth', 2);

    xlabel('X position (m)');
    ylabel('Y position (m)');
    title(titleText);

    hold off;
end
