Scene@ scene_;
Node@ cameraNode;
float yaw = 0.0f; // Camera yaw angle
float pitch = 0.0f; // Camera pitch angle


void Start()
{
    scene_ = Scene();
    scene_.LoadXML(cache.GetFile("Scenes/TestSoftParticles.xml"));
    cameraNode = scene_.GetChild("Camera");
    Viewport@ viewport = Viewport(scene_, cameraNode.GetComponent("Camera"));
    renderer.viewports[0] = viewport;
    File@ file = cache.GetFile("RenderPaths/ForwardHWDepth_SoftParticles.xml");
    XMLFile@ xml = XMLFile();
    xml.Load(file);
    renderer.viewports[0].renderPath.Load(xml);
    renderer.shadowMapSize = 1024;
    SubscribeToEvent("Update", "HandleUpdate");
}


void MoveCamera(float timeStep)
{
    const float MOVE_SPEED = 20.0f;
    const float MOUSE_SENSITIVITY = 0.1f;

    IntVector2 mouseMove = input.mouseMove;
    yaw += MOUSE_SENSITIVITY * mouseMove.x;
    pitch += MOUSE_SENSITIVITY * mouseMove.y;
    pitch = Clamp(pitch, -90.0f, 90.0f);

    cameraNode.rotation = Quaternion(pitch, yaw, 0.0f);

    if (input.keyDown['W'])
        cameraNode.Translate(Vector3(0.0f, 0.0f, 1.0f) * MOVE_SPEED * timeStep);
    if (input.keyDown['S'])
        cameraNode.Translate(Vector3(0.0f, 0.0f, -1.0f) * MOVE_SPEED * timeStep);
    if (input.keyDown['A'])
        cameraNode.Translate(Vector3(-1.0f, 0.0f, 0.0f) * MOVE_SPEED * timeStep);
    if (input.keyDown['D'])
        cameraNode.Translate(Vector3(1.0f, 0.0f, 0.0f) * MOVE_SPEED * timeStep);
}


void HandleUpdate(StringHash eventType, VariantMap& eventData)
{
    float timeStep = eventData["TimeStep"].GetFloat();
    MoveCamera(timeStep);
}
