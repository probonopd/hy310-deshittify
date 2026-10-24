.class public Lio/github/probonopd/hy310projection/CameraActivity;
.super Landroid/app/Activity;
.implements Landroid/view/SurfaceHolder$Callback;

# Full-screen live preview of the projector's camera (the one the auto keystone and auto focus use), through
# the stock camera API. The camera permission is granted by the root command that starts this screen.

.field private cam:Landroid/hardware/Camera;

.method public constructor <init>()V
    .locals 0
    invoke-direct {p0}, Landroid/app/Activity;-><init>()V
    return-void
.end method

.method protected onCreate(Landroid/os/Bundle;)V
    .locals 5
    invoke-super {p0, p1}, Landroid/app/Activity;->onCreate(Landroid/os/Bundle;)V
    invoke-virtual {p0}, Landroid/app/Activity;->getWindow()Landroid/view/Window;
    move-result-object v0
    const/16 v1, 0x80
    invoke-virtual {v0, v1}, Landroid/view/Window;->addFlags(I)V
    new-instance v0, Landroid/view/SurfaceView;
    invoke-direct {v0, p0}, Landroid/view/SurfaceView;-><init>(Landroid/content/Context;)V
    invoke-virtual {v0}, Landroid/view/SurfaceView;->getHolder()Landroid/view/SurfaceHolder;
    move-result-object v1
    invoke-interface {v1, p0}, Landroid/view/SurfaceHolder;->addCallback(Landroid/view/SurfaceHolder$Callback;)V
    # the camera delivers 4:3 only; keep that shape instead of stretching it over the 16:9 screen
    invoke-virtual {p0}, Landroid/app/Activity;->getResources()Landroid/content/res/Resources;
    move-result-object v1
    invoke-virtual {v1}, Landroid/content/res/Resources;->getDisplayMetrics()Landroid/util/DisplayMetrics;
    move-result-object v1
    iget v1, v1, Landroid/util/DisplayMetrics;->heightPixels:I
    mul-int/lit8 v1, v1, 0x4
    div-int/lit8 v1, v1, 0x3
    new-instance v2, Landroid/widget/FrameLayout$LayoutParams;
    const/4 v3, -0x1
    const/16 v4, 0x11
    invoke-direct {v2, v1, v3, v4}, Landroid/widget/FrameLayout$LayoutParams;-><init>(III)V
    new-instance v1, Landroid/widget/FrameLayout;
    invoke-direct {v1, p0}, Landroid/widget/FrameLayout;-><init>(Landroid/content/Context;)V
    const/high16 v3, -0x1000000
    invoke-virtual {v1, v3}, Landroid/view/View;->setBackgroundColor(I)V
    invoke-virtual {v1, v0, v2}, Landroid/view/ViewGroup;->addView(Landroid/view/View;Landroid/view/ViewGroup$LayoutParams;)V
    invoke-virtual {p0, v1}, Landroid/app/Activity;->setContentView(Landroid/view/View;)V
    return-void
.end method

.method public surfaceCreated(Landroid/view/SurfaceHolder;)V
    .locals 3
    :try_start
    const/4 v0, 0x0
    invoke-static {v0}, Landroid/hardware/Camera;->open(I)Landroid/hardware/Camera;
    move-result-object v0
    iput-object v0, p0, Lio/github/probonopd/hy310projection/CameraActivity;->cam:Landroid/hardware/Camera;
    invoke-virtual {v0, p1}, Landroid/hardware/Camera;->setPreviewDisplay(Landroid/view/SurfaceHolder;)V
    invoke-virtual {v0}, Landroid/hardware/Camera;->startPreview()V
    :try_end
    .catch Ljava/lang/Exception; {:try_start .. :try_end} :fail
    return-void

    :fail
    move-exception v0
    invoke-virtual {v0}, Ljava/lang/Throwable;->toString()Ljava/lang/String;
    move-result-object v0
    const/4 v1, 0x1
    invoke-static {p0, v0, v1}, Landroid/widget/Toast;->makeText(Landroid/content/Context;Ljava/lang/CharSequence;I)Landroid/widget/Toast;
    move-result-object v0
    invoke-virtual {v0}, Landroid/widget/Toast;->show()V
    invoke-virtual {p0}, Landroid/app/Activity;->finish()V
    return-void
.end method

.method public surfaceChanged(Landroid/view/SurfaceHolder;III)V
    .locals 0
    return-void
.end method

.method public surfaceDestroyed(Landroid/view/SurfaceHolder;)V
    .locals 2
    iget-object v0, p0, Lio/github/probonopd/hy310projection/CameraActivity;->cam:Landroid/hardware/Camera;
    if-eqz v0, :out
    invoke-virtual {v0}, Landroid/hardware/Camera;->stopPreview()V
    invoke-virtual {v0}, Landroid/hardware/Camera;->release()V
    const/4 v1, 0x0
    iput-object v1, p0, Lio/github/probonopd/hy310projection/CameraActivity;->cam:Landroid/hardware/Camera;
    :out
    return-void
.end method
