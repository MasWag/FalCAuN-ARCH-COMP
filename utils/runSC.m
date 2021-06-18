function simOut = runSC(signal)
    timeVector = signal(:,1);
    ds = Simulink.SimulationData.Dataset;
    throttle = timeseries(signal(:,2), timeVector);
    ds = ds.addElement(throttle, 'input');

    % run simulation
    cd ../SC
    mdl = 'steamcondense_RNN_22';
    load_system(mdl);
    in = Simulink.SimulationInput(mdl);
    in = in.setExternalInput(ds);
    in = in.setModelParameter('StopTime', sprintf("%f", timeVector(end)));
    simOut = sim(in);

    % plot the result
    plot(simOut.tout, simOut.yout)

    % close the system
    close_system(mdl)
    cd ../utils
end

