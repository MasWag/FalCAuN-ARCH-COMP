function simOut = runAT(signal)
    timeVector = signal(:,1);
    ds = Simulink.SimulationData.Dataset;
    throttle = timeseries(signal(:,2), timeVector);
    ds = ds.addElement(throttle, 'throttle');
    brake = timeseries(signal(:,3), timeVector);
    ds = ds.addElement(brake, 'brake');


    % run simulation
    cd ../AT
    init_falcaun
    in = Simulink.SimulationInput(mdl);
    in = in.setExternalInput(ds);
    in = in.setModelParameter('StopTime', sprintf("%f", timeVector(end)));
    simOut = sim(in);

    % plot the result
    plot(simOut.tout, simOut.yout)

    % close the system
    mdl = 'Autotrans_shift';
    close_system(mdl)
    cd ../utils
end

