function joy2joints_msgs()
% Lee los mensajes del topic joy, calcula los deltas del movimiento,
% calcula la cinemática inversa y envia los valores articulares a ROS

global operation_mode;
if strcmp(operation_mode, 'automatic')
    return
end

% Obtiene los valores de los ejes y botones del joypad
global joy_subs;
axes = joy_subs.LatestMessage.Axes';
buttons = joy_subs.LatestMessage.Buttons';

% Obtiene los valores articulareas actuales y la pose del robot
joints = get_actual_joints_values();
pose = get_pose(joints(1:4));
q0 = [joints(1:4), joints(5)*2];
point = [pose(1), pose(2), pose(3)];

% Agregando deltas de los ejes X, Y, Z
delta1 = 0.001;
point(1) = point(1) + delta1*axes(1);
point(2) = point(2) + delta1*axes(2);
point(3) = point(3) + delta1*axes(3);

% Agregando deltas al gripper
delta2 = 0.0;
if buttons(1) == 1 && buttons(2) == 0
    delta2 = -0.002;
end
if buttons(1) == 0 && buttons(2) == 1
    delta2 = 0.002;
end
gripper = q0(5) + delta2;
global min_joints;
global max_joints;
if gripper < min_joints(5)
    gripper = min_joints(5);
end
if gripper > max_joints(5)
    gripper = max_joints(5);
end

% Agregando deltas al ángulo delta del gripper
delta2 = 0.0;
if buttons(3) == 1 && buttons(4) == 0
    delta2 = -0.02;
end
if buttons(3) == 0 && buttons(4) == 1
    delta2 = 0.02;
end
delta_gripper = pose(7) + delta2;

% Calcula la cinemática inversa del robot para el punto y orientación deseados
ik = get_ik(point, delta_gripper, false);
if ik(5) == 0
    disp("Posición inalcanzable para el robot");
    return;
end
q = [ik(1:4), gripper];

% Determina si hubo un cambio apreciable en los deltas y termina la función
% sin cambiar los valores articulares si los deltas son muy pequeños.
delta_abs = max(abs(min(q - q0)), max(q - q0));
disp(delta_abs)
if delta_abs < 0.001
    return;
end

% Publica los valores articulares para que se ejecuten en 0.1 segundos
sendROSmsg(q, 0, 100000);

disp(q)

end