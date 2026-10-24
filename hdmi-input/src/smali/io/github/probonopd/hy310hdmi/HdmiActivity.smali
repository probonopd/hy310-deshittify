.class public Lio/github/probonopd/hy310hdmi/HdmiActivity;
.super Landroid/app/Activity;

# Full-screen viewer for the box's HDMI input through the stock TV Input Framework: a TvView
# tuned to the passthrough URI of an HDMI TvInputInfo. Left/right (or channel up/down) switch
# between several HDMI inputs. No vendor app is involved, only the system's input service.

.field private inputs:Ljava/util/ArrayList;
.field private idx:I
.field private tv:Landroid/media/tv/TvView;

.method public constructor <init>()V
    .locals 0
    invoke-direct {p0}, Landroid/app/Activity;-><init>()V
    return-void
.end method

.method protected onCreate(Landroid/os/Bundle;)V
    .locals 6
    invoke-super {p0, p1}, Landroid/app/Activity;->onCreate(Landroid/os/Bundle;)V

    invoke-virtual {p0}, Landroid/app/Activity;->getWindow()Landroid/view/Window;
    move-result-object v0
    const/16 v1, 0x80
    invoke-virtual {v0, v1}, Landroid/view/Window;->addFlags(I)V

    new-instance v0, Landroid/media/tv/TvView;
    invoke-direct {v0, p0}, Landroid/media/tv/TvView;-><init>(Landroid/content/Context;)V
    iput-object v0, p0, Lio/github/probonopd/hy310hdmi/HdmiActivity;->tv:Landroid/media/tv/TvView;
    invoke-virtual {p0, v0}, Landroid/app/Activity;->setContentView(Landroid/view/View;)V

    const-string v0, "tv_input"
    invoke-virtual {p0, v0}, Landroid/app/Activity;->getSystemService(Ljava/lang/String;)Ljava/lang/Object;
    move-result-object v0
    check-cast v0, Landroid/media/tv/TvInputManager;
    invoke-virtual {v0}, Landroid/media/tv/TvInputManager;->getTvInputList()Ljava/util/List;
    move-result-object v0

    new-instance v1, Ljava/util/ArrayList;
    invoke-direct {v1}, Ljava/util/ArrayList;-><init>()V
    invoke-interface {v0}, Ljava/util/List;->iterator()Ljava/util/Iterator;
    move-result-object v0

    :loop
    invoke-interface {v0}, Ljava/util/Iterator;->hasNext()Z
    move-result v2
    if-eqz v2, :done
    invoke-interface {v0}, Ljava/util/Iterator;->next()Ljava/lang/Object;
    move-result-object v2
    check-cast v2, Landroid/media/tv/TvInputInfo;
    invoke-virtual {v2}, Landroid/media/tv/TvInputInfo;->getType()I
    move-result v3
    # TvInputInfo.TYPE_HDMI
    const/16 v4, 0x3ef
    if-ne v3, v4, :loop

    # insert ordered by input id so that HW1 comes first
    invoke-virtual {v2}, Landroid/media/tv/TvInputInfo;->getId()Ljava/lang/String;
    move-result-object v3
    const/4 v4, 0x0
    :pos
    invoke-virtual {v1}, Ljava/util/ArrayList;->size()I
    move-result v5
    if-ge v4, v5, :insert
    invoke-virtual {v1, v4}, Ljava/util/ArrayList;->get(I)Ljava/lang/Object;
    move-result-object v5
    check-cast v5, Landroid/media/tv/TvInputInfo;
    invoke-virtual {v5}, Landroid/media/tv/TvInputInfo;->getId()Ljava/lang/String;
    move-result-object v5
    invoke-virtual {v5, v3}, Ljava/lang/String;->compareTo(Ljava/lang/String;)I
    move-result v5
    if-gtz v5, :insert
    add-int/lit8 v4, v4, 0x1
    goto :pos
    :insert
    invoke-virtual {v1, v4, v2}, Ljava/util/ArrayList;->add(ILjava/lang/Object;)V
    goto :loop

    :done
    iput-object v1, p0, Lio/github/probonopd/hy310hdmi/HdmiActivity;->inputs:Ljava/util/ArrayList;
    invoke-virtual {v1}, Ljava/util/ArrayList;->isEmpty()Z
    move-result v0
    if-eqz v0, :have

    const-string v0, "No HDMI input found"
    const/4 v1, 0x1
    invoke-static {p0, v0, v1}, Landroid/widget/Toast;->makeText(Landroid/content/Context;Ljava/lang/CharSequence;I)Landroid/widget/Toast;
    move-result-object v0
    invoke-virtual {v0}, Landroid/widget/Toast;->show()V
    invoke-virtual {p0}, Landroid/app/Activity;->finish()V
    return-void

    :have
    const-string v0, "hdmi"
    const/4 v2, 0x0
    invoke-virtual {p0, v0, v2}, Landroid/app/Activity;->getSharedPreferences(Ljava/lang/String;I)Landroid/content/SharedPreferences;
    move-result-object v0
    const-string v3, "idx"
    invoke-interface {v0, v3, v2}, Landroid/content/SharedPreferences;->getInt(Ljava/lang/String;I)I
    move-result v0
    invoke-virtual {v1}, Ljava/util/ArrayList;->size()I
    move-result v1
    rem-int/2addr v0, v1
    iput v0, p0, Lio/github/probonopd/hy310hdmi/HdmiActivity;->idx:I
    return-void
.end method

.method protected onResume()V
    .locals 1
    invoke-super {p0}, Landroid/app/Activity;->onResume()V
    iget-object v0, p0, Lio/github/probonopd/hy310hdmi/HdmiActivity;->inputs:Ljava/util/ArrayList;
    invoke-virtual {v0}, Ljava/util/ArrayList;->isEmpty()Z
    move-result v0
    if-nez v0, :out
    invoke-direct {p0}, Lio/github/probonopd/hy310hdmi/HdmiActivity;->tune()V
    :out
    return-void
.end method

.method protected onPause()V
    .locals 1
    invoke-super {p0}, Landroid/app/Activity;->onPause()V
    iget-object v0, p0, Lio/github/probonopd/hy310hdmi/HdmiActivity;->tv:Landroid/media/tv/TvView;
    invoke-virtual {v0}, Landroid/media/tv/TvView;->reset()V
    return-void
.end method

.method public onKeyDown(ILandroid/view/KeyEvent;)Z
    .locals 2
    iget-object v0, p0, Lio/github/probonopd/hy310hdmi/HdmiActivity;->inputs:Ljava/util/ArrayList;
    invoke-virtual {v0}, Ljava/util/ArrayList;->isEmpty()Z
    move-result v0
    if-nez v0, :default

    # DPAD_RIGHT, CHANNEL_UP: next input
    const/16 v0, 0x16
    if-eq p1, v0, :next
    const/16 v0, 0xa6
    if-eq p1, v0, :next
    # DPAD_LEFT, CHANNEL_DOWN: previous input
    const/16 v0, 0x15
    if-eq p1, v0, :prev
    const/16 v0, 0xa7
    if-eq p1, v0, :prev

    :default
    invoke-super {p0, p1, p2}, Landroid/app/Activity;->onKeyDown(ILandroid/view/KeyEvent;)Z
    move-result v0
    return v0

    :next
    const/4 v0, 0x1
    invoke-direct {p0, v0}, Lio/github/probonopd/hy310hdmi/HdmiActivity;->step(I)V
    return v0

    :prev
    const/4 v0, -0x1
    invoke-direct {p0, v0}, Lio/github/probonopd/hy310hdmi/HdmiActivity;->step(I)V
    const/4 v0, 0x1
    return v0
.end method

.method private step(I)V
    .locals 3
    iget-object v0, p0, Lio/github/probonopd/hy310hdmi/HdmiActivity;->inputs:Ljava/util/ArrayList;
    invoke-virtual {v0}, Ljava/util/ArrayList;->size()I
    move-result v1
    iget v2, p0, Lio/github/probonopd/hy310hdmi/HdmiActivity;->idx:I
    add-int/2addr v2, p1
    add-int/2addr v2, v1
    rem-int/2addr v2, v1
    iput v2, p0, Lio/github/probonopd/hy310hdmi/HdmiActivity;->idx:I
    invoke-direct {p0}, Lio/github/probonopd/hy310hdmi/HdmiActivity;->tune()V
    return-void
.end method

.method private tune()V
    .locals 6
    iget-object v0, p0, Lio/github/probonopd/hy310hdmi/HdmiActivity;->inputs:Ljava/util/ArrayList;
    iget v1, p0, Lio/github/probonopd/hy310hdmi/HdmiActivity;->idx:I
    invoke-virtual {v0, v1}, Ljava/util/ArrayList;->get(I)Ljava/lang/Object;
    move-result-object v2
    check-cast v2, Landroid/media/tv/TvInputInfo;

    invoke-virtual {v2}, Landroid/media/tv/TvInputInfo;->getId()Ljava/lang/String;
    move-result-object v3
    invoke-static {v3}, Landroid/media/tv/TvContract;->buildChannelUriForPassthroughInput(Ljava/lang/String;)Landroid/net/Uri;
    move-result-object v4
    iget-object v5, p0, Lio/github/probonopd/hy310hdmi/HdmiActivity;->tv:Landroid/media/tv/TvView;
    invoke-virtual {v5, v3, v4}, Landroid/media/tv/TvView;->tune(Ljava/lang/String;Landroid/net/Uri;)V

    new-instance v3, Ljava/lang/StringBuilder;
    invoke-direct {v3}, Ljava/lang/StringBuilder;-><init>()V
    const-string v4, "HDMI "
    invoke-virtual {v3, v4}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    add-int/lit8 v4, v1, 0x1
    invoke-virtual {v3, v4}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;
    const-string v4, "/"
    invoke-virtual {v3, v4}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    invoke-virtual {v0}, Ljava/util/ArrayList;->size()I
    move-result v4
    invoke-virtual {v3, v4}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;
    invoke-virtual {v3}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
    move-result-object v3
    const/4 v4, 0x0
    invoke-static {p0, v3, v4}, Landroid/widget/Toast;->makeText(Landroid/content/Context;Ljava/lang/CharSequence;I)Landroid/widget/Toast;
    move-result-object v3
    invoke-virtual {v3}, Landroid/widget/Toast;->show()V

    const-string v3, "hdmi"
    invoke-virtual {p0, v3, v4}, Landroid/app/Activity;->getSharedPreferences(Ljava/lang/String;I)Landroid/content/SharedPreferences;
    move-result-object v3
    invoke-interface {v3}, Landroid/content/SharedPreferences;->edit()Landroid/content/SharedPreferences$Editor;
    move-result-object v3
    const-string v4, "idx"
    invoke-interface {v3, v4, v1}, Landroid/content/SharedPreferences$Editor;->putInt(Ljava/lang/String;I)Landroid/content/SharedPreferences$Editor;
    move-result-object v3
    invoke-interface {v3}, Landroid/content/SharedPreferences$Editor;->apply()V
    return-void
.end method
