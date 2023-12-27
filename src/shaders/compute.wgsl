struct BoidStruct {
  offset: vec2f,
  velocity: vec2f,
  scale: vec2f,
};

@group(0) @binding(0)
var<storage, read_write> boidStructs: array<BoidStruct>;

@compute @workgroup_size(128)
fn compute(@builtin(global_invocation_id) GlobalInvocationID : vec3<u32>) {
  var index = GlobalInvocationID.x;

  var paramsDeltaT = 0.01;
  var paramsRule1Distance = 0.1;
  var paramsRule2Distance = 0.025;
  var paramsRule3Distance = 0.025;
  var paramsRule1Scale = 0.02;
  var paramsRule2Scale = 0.05;
  var paramsRule3Scale = 0.005;

  var vPos = boidStructs[index].offset;
  var vVel = boidStructs[index].velocity;
  var cMass = vec2(0.0);
  var cVel = vec2(0.0);
  var colVel = vec2(0.0);
  var cMassCount = 0u;
  var cVelCount = 0u;
  var pos : vec2<f32>;
  var vel : vec2<f32>;

  for (var i = 0u; i < arrayLength(&boidStructs); i++) {
    if (i == index) {
      continue;
    }

    pos = boidStructs[i].offset.xy;
    vel = boidStructs[i].velocity.xy;
    if (distance(pos, vPos) < paramsRule1Distance) {
      cMass += pos;
      cMassCount++;
    }
    if (distance(pos, vPos) < paramsRule2Distance) {
      colVel -= pos - vPos;
    }
    if (distance(pos, vPos) < paramsRule3Distance) {
      cVel += vel;
      cVelCount++;
    }
  }

  if (cMassCount > 0) {
    cMass = (cMass / vec2(f32(cMassCount))) - vPos;
  }
  if (cVelCount > 0) {
    cVel /= f32(cVelCount);
  }
  vVel += (cMass * paramsRule1Scale) + (colVel * paramsRule2Scale) + (cVel * paramsRule3Scale);

  // clamp velocity for a more pleasing simulation
  vVel = normalize(vVel) * clamp(length(vVel), 0.0, 0.1);

  // kinematic update
  vPos = vPos + (vVel * paramsDeltaT);

  // Wrap around boundary
  if (vPos.x < -1.0) {
    vPos.x = 1.0;
  }
  if (vPos.x > 1.0) {
    vPos.x = -1.0;
  }
  if (vPos.y < -1.0) {
    vPos.y = 1.0;
  }
  if (vPos.y > 1.0) {
    vPos.y = -1.0;
  }

  boidStructs[index].offset = vPos;
  boidStructs[index].velocity = vVel;
}