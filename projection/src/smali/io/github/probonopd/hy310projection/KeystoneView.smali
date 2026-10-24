.class public Lio/github/probonopd/hy310projection/KeystoneView;
.super Landroid/view/View;

# A 1 px white frame along the screen edge with a small square in each corner (the marked one larger and yellow), so
# the projected picture shows what the keystone correction does to the four corners.

.field sel:I
.field private line:Landroid/graphics/Paint;
.field private fill:Landroid/graphics/Paint;

.method public constructor <init>(Landroid/content/Context;)V
    .locals 3
    invoke-direct {p0, p1}, Landroid/view/View;-><init>(Landroid/content/Context;)V
    new-instance v0, Landroid/graphics/Paint;
    invoke-direct {v0}, Landroid/graphics/Paint;-><init>()V
    sget-object v1, Landroid/graphics/Paint$Style;->STROKE:Landroid/graphics/Paint$Style;
    invoke-virtual {v0, v1}, Landroid/graphics/Paint;->setStyle(Landroid/graphics/Paint$Style;)V
    const/high16 v1, 0x3f800000
    invoke-virtual {v0, v1}, Landroid/graphics/Paint;->setStrokeWidth(F)V
    const/4 v2, -0x1
    invoke-virtual {v0, v2}, Landroid/graphics/Paint;->setColor(I)V
    iput-object v0, p0, Lio/github/probonopd/hy310projection/KeystoneView;->line:Landroid/graphics/Paint;
    new-instance v0, Landroid/graphics/Paint;
    invoke-direct {v0}, Landroid/graphics/Paint;-><init>()V
    sget-object v1, Landroid/graphics/Paint$Style;->FILL:Landroid/graphics/Paint$Style;
    invoke-virtual {v0, v1}, Landroid/graphics/Paint;->setStyle(Landroid/graphics/Paint$Style;)V
    iput-object v0, p0, Lio/github/probonopd/hy310projection/KeystoneView;->fill:Landroid/graphics/Paint;
    return-void
.end method

.method public setSel(I)V
    .locals 0
    iput p1, p0, Lio/github/probonopd/hy310projection/KeystoneView;->sel:I
    invoke-virtual {p0}, Landroid/view/View;->invalidate()V
    return-void
.end method

# corner index: 0 top left, 1 top right, 2 bottom right, 3 bottom left
.method private corner(Landroid/graphics/Canvas;IFF)V
    .locals 12
    iget v0, p0, Lio/github/probonopd/hy310projection/KeystoneView;->sel:I
    if-ne v0, p2, :normal
    const/high16 v1, 0x42000000
    const v2, -0x14c5
    goto :color
    :normal
    const/high16 v1, 0x41400000
    const/4 v2, -0x1
    :color
    iget-object v3, p0, Lio/github/probonopd/hy310projection/KeystoneView;->fill:Landroid/graphics/Paint;
    invoke-virtual {v3, v2}, Landroid/graphics/Paint;->setColor(I)V
    const/4 v4, 0x0
    const/4 v5, 0x0
    const/4 v0, 0x1
    if-eq p2, v0, :right
    const/4 v0, 0x2
    if-ne p2, v0, :ycheck
    :right
    sub-float v4, p3, v1
    :ycheck
    const/4 v0, 0x2
    if-eq p2, v0, :bottom
    const/4 v0, 0x3
    if-ne p2, v0, :draw
    :bottom
    sub-float v5, p4, v1
    :draw
    add-float v9, v4, v1
    add-float v10, v5, v1
    move-object v6, p1
    move v7, v4
    move v8, v5
    move-object v11, v3
    invoke-virtual/range {v6 .. v11}, Landroid/graphics/Canvas;->drawRect(FFFFLandroid/graphics/Paint;)V
    return-void
.end method

.method protected onDraw(Landroid/graphics/Canvas;)V
    .locals 13
    invoke-super {p0, p1}, Landroid/view/View;->onDraw(Landroid/graphics/Canvas;)V
    invoke-virtual {p0}, Landroid/view/View;->getWidth()I
    move-result v0
    invoke-virtual {p0}, Landroid/view/View;->getHeight()I
    move-result v1
    int-to-float v2, v0
    int-to-float v3, v1
    const/high16 v4, 0x3f000000
    sub-float v5, v2, v4
    sub-float v6, v3, v4
    move-object v7, p1
    move v8, v4
    move v9, v4
    move v10, v5
    move v11, v6
    iget-object v12, p0, Lio/github/probonopd/hy310projection/KeystoneView;->line:Landroid/graphics/Paint;
    invoke-virtual/range {v7 .. v12}, Landroid/graphics/Canvas;->drawRect(FFFFLandroid/graphics/Paint;)V
    const/4 v0, 0x0
    invoke-direct {p0, p1, v0, v2, v3}, Lio/github/probonopd/hy310projection/KeystoneView;->corner(Landroid/graphics/Canvas;IFF)V
    const/4 v0, 0x1
    invoke-direct {p0, p1, v0, v2, v3}, Lio/github/probonopd/hy310projection/KeystoneView;->corner(Landroid/graphics/Canvas;IFF)V
    const/4 v0, 0x2
    invoke-direct {p0, p1, v0, v2, v3}, Lio/github/probonopd/hy310projection/KeystoneView;->corner(Landroid/graphics/Canvas;IFF)V
    const/4 v0, 0x3
    invoke-direct {p0, p1, v0, v2, v3}, Lio/github/probonopd/hy310projection/KeystoneView;->corner(Landroid/graphics/Canvas;IFF)V
    return-void
.end method
