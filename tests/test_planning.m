function tests = test_planning
% TEST_PLANNING Integration and consistency tests for the LTE planner.
%
% Run from the repository root:
%
%   results = runtests(fullfile('tests', 'test_planning.m'));
%   disp(results);
%   assert(all([results.Passed]), 'Planning tests failed.');
%
% The simulator runs once in a temporary project directory.
% Generated files are removed after data has been collected.
%
% IMPORTANT:
% The simulation script contains "close all" and will close
% existing MATLAB figures.
%
% These tests verify software consistency, not field accuracy.

    tests = functiontests(localfunctions);
end

function setupOnce(testCase)

    testFolder = fileparts(mfilename('fullpath'));
    projectRoot = fileparts(testFolder);

    sourceScript = fullfile(projectRoot, 'src', ...
        'lte_radio_network_planning.m');

    assert(exist(sourceScript, 'file') == 2, ...
        'Planning:MissingScript', ...
        'Expected simulation script: %s', sourceScript);

    temporaryRoot = tempname;
    temporarySrc = fullfile(temporaryRoot, 'src');
    mkdir(temporarySrc);

    previousFolder = pwd;
    previousVisibility = get(groot, 'DefaultFigureVisible');

    cleanupGuard = onCleanup(@() cleanupEnvironment( ...
        previousFolder, previousVisibility, temporaryRoot)); %#ok<NASGU>

    temporaryScript = fullfile(temporarySrc, ...
        'lte_radio_network_planning.m');

    copyfile(sourceScript, temporaryScript);

    % Supports both the original relative output path and the
    % improved script-relative output path.
    cd(temporaryRoot);
    set(groot, 'DefaultFigureVisible', 'off');

    testCase.TestData = executeSimulation(temporaryScript);
end

function data = executeSimulation(scriptPath)
% Isolate the script's "clear" command from the test fixture.
% Assign the output structure only after the script finishes.

    run(scriptPath);

    data.cfg = cfg;
    data.summary = summary;
    data.reference = reference;
    data.sites = referenceSites;

    expectedFiles = { ...
        'scenario_summary.csv', ...
        'planning_results.mat', ...
        'deployment.png', ...
        'radio_maps.png', ...
        'scenario_comparison.png', ...
        'path_loss.png'};

    data.outputExists = false(size(expectedFiles));
    data.outputBytes = zeros(size(expectedFiles));

    for k = 1:numel(expectedFiles)
        outputPath = fullfile(cfg.outputFolder, expectedFiles{k});

        data.outputExists(k) = exist(outputPath, 'file') == 2;

        if data.outputExists(k)
            info = dir(outputPath);
            data.outputBytes(k) = info.bytes;
        end
    end

    data.exportedSummary = readtable( ...
        fullfile(cfg.outputFolder, 'scenario_summary.csv'));

    data.savedResults = load( ...
        fullfile(cfg.outputFolder, 'planning_results.mat'));
end

function cleanupEnvironment(previousFolder, ...
    previousVisibility, temporaryRoot)

    close all;
    set(groot, 'DefaultFigureVisible', previousVisibility);
    cd(previousFolder);

    if exist(temporaryRoot, 'dir') == 7
        rmdir(temporaryRoot, 's');
    end
end

function testScenarioCountAndCombinations(testCase)

    T = testCase.TestData.summary;
    cfg = testCase.TestData.cfg;

    [D, S, F] = ndgrid( ...
        cfg.isdValues_m, cfg.sectorValues, cfg.reuseValues);

    expected = sortrows([D(:), S(:), F(:)]);
    actual = sortrows(T{:, ...
        {'ISD_m', 'SectorsPerSite', 'ReuseFactor'}});

    verifyEqual(testCase, height(T), 18);
    verifyEqual(testCase, actual, expected);
end

function testSummarySchema(testCase)

    T = testCase.TestData.summary;

    expectedNames = { ...
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
        'P5RateProxy_Mbps'};

    verifyEqual(testCase, T.Properties.VariableNames, expectedNames);
    verifyTrue(testCase, all(isfinite(T{:,:}(:))));
end

function testDeploymentGeometry(testCase)

    sites = testCase.TestData.sites;
    T = testCase.TestData.summary;

    verifySize(testCase, sites, [19 2]);
    verifyEqual(testCase, size(unique(sites, 'rows'), 1), 19);
    verifyTrue(testCase, any(all(sites == 0, 2)));
    verifyEqual(testCase, T.NumberOfSites, 19 * ones(height(T),1));

    % The stored reference deployment uses an ISD of 750 m.
    dx = bsxfun(@minus, sites(:,1), sites(:,1)');
    dy = bsxfun(@minus, sites(:,2), sites(:,2)');

    distances = hypot(dx, dy);
    distances(1:size(sites,1)+1:end) = Inf;

    verifyEqual(testCase, min(distances(:)), 750, ...
        'AbsTol', 1e-9);
end

function testSiteDensity(testCase)

    T = testCase.TestData.summary;

    expectedDensity = 1e6 ./ ...
        ((sqrt(3)/2) .* T.ISD_m.^2);

    verifyEqual(testCase, T.SiteDensity_per_km2, ...
        expectedDensity, 'AbsTol', 1e-10);
end

function testResourceAllocation(testCase)

    T = testCase.TestData.summary;
    cfg = testCase.TestData.cfg;

    expectedRB = floor(cfg.totalRB ./ T.ReuseFactor);
    expectedUnused = cfg.totalRB - ...
        T.ReuseFactor .* expectedRB;

    verifyEqual(testCase, T.RB_PerCell, expectedRB);
    verifyEqual(testCase, T.UnassignedRB, expectedUnused);

    reconstructedTotal = ...
        T.ReuseFactor .* T.RB_PerCell + T.UnassignedRB;

    verifyEqual(testCase, reconstructedTotal, ...
        cfg.totalRB * ones(height(T),1));
end

function testMetricBounds(testCase)

    T = testCase.TestData.summary;

    verifyTrue(testCase, all(T.Coverage_percent >= 0));
    verifyTrue(testCase, all(T.Coverage_percent <= 100));

    verifyTrue(testCase, all(T.MeanRateProxy_Mbps >= 0));
    verifyTrue(testCase, all(T.P5RateProxy_Mbps >= 0));
end

function testReferenceMapDimensions(testCase)

    R = testCase.TestData.reference;
    cfg = testCase.TestData.cfg;

    expectedSize = [cfg.gridSize cfg.gridSize];

    fields = { ...
        'X', 'Y', 'rx_dBm', 'sinr_dB', ...
        'servingCell', 'covered', 'rateProxy_Mbps', ...
        'evaluationMask'};

    for k = 1:numel(fields)
        verifySize(testCase, R.(fields{k}), expectedSize);
    end

    verifyTrue(testCase, any(R.evaluationMask(:)));
    verifyTrue(testCase, islogical(R.covered));
    verifyTrue(testCase, islogical(R.evaluationMask));
end

function testReferenceValuesAndServingCells(testCase)

    R = testCase.TestData.reference;
    sites = testCase.TestData.sites;

    verifyTrue(testCase, all(isfinite(R.rx_dBm(:))));
    verifyTrue(testCase, all(isfinite(R.sinr_dB(:))));
    verifyTrue(testCase, all(isfinite(R.rateProxy_Mbps(:))));

    maximumCellID = 3 * size(sites,1);

    verifyTrue(testCase, all(R.servingCell(:) >= 1));
    verifyTrue(testCase, all(R.servingCell(:) <= maximumCellID));

    verifyEqual(testCase, R.servingCell, floor(R.servingCell));

    verifyTrue(testCase, all(R.rateProxy_Mbps(:) >= 0));

    verifyEqual(testCase, R.rbPerCell, 50);
    verifyEqual(testCase, R.unassignedRB, 0);
end

function testCoverageClassification(testCase)

    R = testCase.TestData.reference;
    cfg = testCase.TestData.cfg;

    expectedCoverage = ...
        R.rx_dBm >= cfg.rxThreshold_dBm & ...
        R.sinr_dB >= cfg.sinrThreshold_dB;

    verifyEqual(testCase, R.covered, expectedCoverage);
end

function testRateProxyCalculation(testCase)

    R = testCase.TestData.reference;
    cfg = testCase.TestData.cfg;

    bandwidth = R.rbPerCell * cfg.rbBandwidth_Hz;
    linearSINR = 10.^(R.sinr_dB / 10);

    expectedRate = ...
        bandwidth .* log2(1 + linearSINR) / 1e6;

    expectedRate(~R.covered) = 0;

    verifyEqual(testCase, R.rateProxy_Mbps, expectedRate, ...
        'AbsTol', 1e-8);

    verifyTrue(testCase, ...
        all(R.rateProxy_Mbps(~R.covered) == 0));
end

function testReferenceSummaryConsistency(testCase)

    T = testCase.TestData.summary;
    R = testCase.TestData.reference;

    selected = ...
        T.ISD_m == 750 & ...
        T.SectorsPerSite == 3 & ...
        T.ReuseFactor == 1;

    verifyEqual(testCase, nnz(selected), 1);

    mask = R.evaluationMask;

    coverage = 100 * mean(R.covered(mask));
    meanSINR = mean(R.sinr_dB(mask));

    rates = R.rateProxy_Mbps(mask);
    meanRate = mean(rates);

    sortedRates = sort(rates);
    p5Index = max(1, ceil(0.05 * numel(sortedRates)));
    p5Rate = sortedRates(p5Index);

    verifyEqual(testCase, T.Coverage_percent(selected), ...
        coverage, 'AbsTol', 1e-10);

    verifyEqual(testCase, T.MeanSINR_dB(selected), ...
        meanSINR, 'AbsTol', 1e-10);

    verifyEqual(testCase, T.MeanRateProxy_Mbps(selected), ...
        meanRate, 'AbsTol', 1e-10);

    verifyEqual(testCase, T.P5RateProxy_Mbps(selected), ...
        p5Rate, 'AbsTol', 1e-10);
end

function testGeneratedOutputFiles(testCase)

    data = testCase.TestData;

    verifyTrue(testCase, all(data.outputExists));
    verifyTrue(testCase, all(data.outputBytes > 0));
end

function testCSVExportConsistency(testCase)

    original = testCase.TestData.summary;
    exported = testCase.TestData.exportedSummary;

    verifyEqual(testCase, exported.Properties.VariableNames, ...
        original.Properties.VariableNames);

    verifyEqual(testCase, exported{:,:}, original{:,:}, ...
        'AbsTol', 1e-8);
end

function testMATExportConsistency(testCase)

    data = testCase.TestData;
    saved = data.savedResults;

    requiredFields = { ...
        'cfg', 'summary', 'reference', 'referenceSites'};

    verifyTrue(testCase, all(isfield(saved, requiredFields)));

    verifyEqual(testCase, saved.cfg, data.cfg);
    verifyEqual(testCase, saved.summary, data.summary);
    verifyEqual(testCase, saved.reference, data.reference);
    verifyEqual(testCase, saved.referenceSites, data.sites);
end
