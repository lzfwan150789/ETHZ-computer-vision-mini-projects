%
% Use these variables to enable/disable different parts of the script.
%
loadImages           = true;  % also displays silhouettes
displayVolumeCorners = true;
computeVisualHull    = true;
displayVolumeSlices  = false;
displayIsoSurface    = true;

%
% Adjust these variables, one at a time, to get a good visual hull.
%

% Task 9.1 silhouette threshold

% 110 or 120 seems good
% at 130 140 we start loosing stuff during part of the turn
silhouetteThreshold = 120; 

% Task 9.2 define bounding box
bbox = [0 -0.5 0; 3 3 3]; % [minX minY minZ; maxX maxY maxZ]; default value
% bbox = [0.25 -0.11 -1.8; 2.07 1.1 2.5]; % [minX minY minZ; maxX maxY maxZ];
bbox = [0.3 -0.15 -1.8; 2.1 1.1 2.5]; % [minX minY minZ; maxX maxY maxZ];
volumeX = 128;
volumeY = 128;
volumeZ = 256;
volumeThreshold = 17;

home;
numCameras = 18;

if loadImages
    % Load silhouette images and projection matrices
    for n=1:numCameras
        Ps{n} = textread(sprintf('../data/david_%02d.pa',n-1));
        Ps{n} = [eye(3,2) [1 1 1]']*Ps{n};  % add 1 for one-based indices
        ims{n} = imread(sprintf('../data/david_%02d.jpg',n-1));
        sils{n} = rgb2gray(ims{n})>silhouetteThreshold;
        
        figure(1);
        subplot(1,2,1);
        imshow(sils{n});
        subplot(1,2,2);
        imshow(double(rgb2gray(ims{n}))/255.*sils{n});
        drawnow;
    end
end

% Define transformation from volume to world coordinates.
T = [eye(4,3) [bbox(1,:) 1]'] * ...
    diag([(bbox(2,1)-bbox(1,1))/volumeX ...
          (bbox(2,2)-bbox(1,2))/volumeY ...
          (bbox(2,3)-bbox(1,3))/volumeZ ...
          1]);
T = [1  0 0 0; ...
     0  0 1 0; ...  % flip y and z axes for better display in matlab figure (isosurface)
     0 -1 0 0; ...
     0  0 0 1] * T;
T = T*[eye(4,3) [-[1 1 1] 1]'];  % subtract 1 for one-based indices

if displayVolumeCorners
    % Draw projection of volume corners.
    for n=1:numCameras
        figure(2);
        hold off;
        imshow(ims{n});
        hold on;
        corners = [[      0       0       0 1]' ...
                   [      0       0 volumeZ 1]' ...
                   [      0 volumeY       0 1]' ...
                   [      0 volumeY volumeZ 1]' ...
                   [volumeX       0       0 1]' ...
                   [volumeX       0 volumeZ 1]' ...
                   [volumeX volumeY       0 1]' ...
                   [volumeX volumeY volumeZ 1]'];
        pcorners = Ps{n}*T*corners;
        pcorners = pcorners./repmat(pcorners(3,:),3,1);
        plot(pcorners(1,:),pcorners(2,:),'g*');
        drawnow;
        pause(0.1);
    end
end

if computeVisualHull
    % Define volume.
    volume = zeros(volumeX,volumeY,volumeZ);
    
    % Visual hull computation    
    % Task 9.3 Visual hull computation
    %   - add one to volume if projection is within silhouette region
    
    for n = 1:numCameras
        silsn = sils{n}; % 480x640 imgage with true or false (in silhouette)
        Psn = Ps{n}; 
        
        % over each voxel
        for x = 1:volumeX
            for y = 1:volumeY
                for z = 1:volumeZ
%                   transformation from volume to world coordinates
                    XYZ = T*[x,y,z,1]';
%                   go from 3d worl coordinates to image coordinates
                    xy = Psn*XYZ;
%                   such that homogenous coordinate = 1
                    xy = xy/xy(end);
%                     Check if the pixel is activated 
                    if silsn(round(xy(2)),round(xy(1))) == 1
                        % if activated, give +1 to the voxel
                        volume(x,y,z) = volume(x,y,z) + 1;
                    end
                end
            end
        end
    end
        
end

if displayVolumeSlices
    figure(3);
    hold off;
    for n=1:size(volume,3)
        imagesc(volume(:,:,n));
        drawnow;
        pause(0.1);
    end
end

if displayIsoSurface
    % display result
    figure(4);
    clf;
    grid on;
    xlabel('x');
    ylabel('y');
    zlabel('z');
    hold on;
    [xMesh yMesh zMesh] = meshgrid(1:volumeY,1:volumeX,1:volumeZ);
    pt = patch(isosurface(yMesh, xMesh, zMesh, volume, volumeThreshold));
    set(pt,'FaceColor','red','EdgeColor','none');
    axis equal;
    daspect([volumeX/(bbox(2,1)-bbox(1,1)) volumeY/(bbox(2,2)-bbox(1,2)) volumeZ/(bbox(2,3)-bbox(1,3))]);
    camlight(0,0);
    camlight(180,0);
    camlight(0,90);
    camlight(0,-90);
    lighting phong;
    view(30,30);
end


