/*
 * Copyright (C) The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package com.app.flutter.mtpl.selfie_ocr_mtpl;

import android.app.Activity;
import android.content.res.Resources;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.os.Build;
import android.view.View;
import android.widget.ImageView;

import androidx.annotation.RequiresApi;

import com.app.flutter.mtpl.selfie_ocr_mtpl.ui.camera.GraphicOverlay;
import com.google.android.gms.vision.face.Face;

/**
 * Graphic instance for rendering face position, orientation, and landmarks within an associated
 * graphic overlay view.
 */
class FaceGraphic extends GraphicOverlay.Graphic {
    private static final float FACE_POSITION_RADIUS = 10.0f;
    private static final float ID_TEXT_SIZE = 40.0f;
    private static final float ID_Y_OFFSET = 50.0f;
    private static final float ID_X_OFFSET = -50.0f;
    private static final float BOX_STROKE_WIDTH = 5.0f;

    updateEyeBlink eyeBlink;

    private static final int COLOR_CHOICES[] = {
//        Color.BLUE,
//        Color.CYAN,
            Color.TRANSPARENT,
//        Color.MAGENTA,
//        Color.RED,
//        Color.WHITE,
//        Color.YELLOW
    };

   /* private static final int COLOR_CHOICES[] = {
            Color.TRANSPARENT
    };
*/

    private static int mCurrentColorIndex = 0;

    private Paint mFacePositionPaint;
    private Paint mIdPaint;
    private Paint mBoxPaint;
    float overlayX;
    float overlayY;
    private volatile Face mFace;
    private int mFaceId;
    private float mFaceHappiness;
    boolean isFirst = false;
    Activity activity;

    //    private ImageView imageViewCircle;
    private ImageView imageViewCircleNew;


    public void setImageViewCircle(ImageView imageViewCircleNew) {
//        this.imageViewCircle = imageViewCircle;
        this.imageViewCircleNew = imageViewCircleNew;

//        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
//            imageViewCircle.setImageDrawable(activity.getResources().getDrawable(R.drawable.rounded_border_white, activity.getTheme()));
//        } else {
//            imageViewCircle.setImageDrawable(activity.getResources().getDrawable(R.drawable.rounded_border_white));
//        }
//        imageViewCircle.setImageDrawable(activity.getDrawable(R.drawable.rounded_border_white));
    }

    FaceGraphic(GraphicOverlay overlay) {
        super(overlay);

        mCurrentColorIndex = (mCurrentColorIndex + 1) % COLOR_CHOICES.length;
        final int selectedColor = COLOR_CHOICES[mCurrentColorIndex];

        mFacePositionPaint = new Paint();
        mFacePositionPaint.setColor(selectedColor);

        mIdPaint = new Paint();
        mIdPaint.setColor(selectedColor);
        mIdPaint.setTextSize(ID_TEXT_SIZE);

        mBoxPaint = new Paint();
        mBoxPaint.setColor(selectedColor);
        mBoxPaint.setStyle(Paint.Style.STROKE);
        mBoxPaint.setStrokeWidth(BOX_STROKE_WIDTH);
    }

    void setId(int id) {
        mFaceId = id;
    }


    /**
     * Updates the face instance from the detection of the most recent frame.  Invalidates the
     * relevant portions of the overlay to trigger a redraw.
     */
    void updateFace(Activity activity, Face face, float overlayX, float overlayY, updateEyeBlink mUpdateEyeBlink) {
        this.activity = activity;
        mFace = face;
        isFirst = true;
        this.overlayX = overlayX;
        this.overlayY = overlayY;
        postInvalidate();
        eyeBlink = mUpdateEyeBlink;
//        mUpdateEyeBlink.inCircle();

    }

    /**
     * Draws the face annotations for position on the supplied canvas.
     */
    @RequiresApi(api = Build.VERSION_CODES.LOLLIPOP)
    @Override
    public void draw(Canvas canvas) {
        Face face = mFace;
        if (face == null) {
            return;
        }

        // Draws a circle at the position of the detected face, with the face's track id below.
        float x = translateX(face.getPosition().x + face.getWidth() / 2);
        float y = translateY(face.getPosition().y + face.getHeight() / 2);
//        canvas.drawCircle(x, y, FACE_POSITION_RADIUS, mFacePositionPaint);
//        canvas.drawText("id: " + mFaceId, x + ID_X_OFFSET, y + ID_Y_OFFSET, mIdPaint);
//        canvas.drawText("happiness: " + String.format("%.2f", face.getIsSmilingProbability()), x - ID_X_OFFSET, y - ID_Y_OFFSET, mIdPaint);
//        canvas.drawText("right eye: " + String.format("%.2f", face.getIsRightEyeOpenProbability()), x + ID_X_OFFSET * 2, y + ID_Y_OFFSET * 2, mIdPaint);
//        canvas.drawText("left eye: " + String.format("%.2f", face.getIsLeftEyeOpenProbability()), x - ID_X_OFFSET*2, y - ID_Y_OFFSET*2, mIdPaint);

        // Draws a bounding box around the face.
        float xOffset = scaleX(face.getWidth() / 2.0f);
        float yOffset = scaleY(face.getHeight() / 2.0f);
        float left = x - xOffset;
        float top = y - yOffset;
        float right = x + xOffset;
        float bottom = y + yOffset;
        canvas.drawOval(left, top, right, bottom, mBoxPaint);

        float diffX = overlayX - left;
        float diffY = overlayY - top;
        float faceWidth = right - left;
        float faceheight = bottom - top;
        int overlaySize = dpToPx(255);

        if (-250 < diffX &&
                diffX < 250 &&
                -250 < diffY &&
                diffY < 250) {


            switch (detectFaceInside(overlaySize, faceWidth, faceheight)) {
                case 0:
                   // Toast.makeText(activity, "Zoom In", Toast.LENGTH_SHORT).show();
                    imageViewCircleNew.setVisibility(View.INVISIBLE);
                    eyeBlink.inCircle(false);
                    break;
                case 1:
                  //  Toast.makeText(activity, "Your face in Circle", Toast.LENGTH_SHORT).show();
                    imageViewCircleNew.setVisibility(View.VISIBLE);
                    eyeBlink.inCircle(true);
                    break;
                case 2:
                   // Toast.makeText(activity, "Zoom out", Toast.LENGTH_SHORT).show();
                    imageViewCircleNew.setVisibility(View.INVISIBLE);
                    eyeBlink.inCircle(false);
                    break;
                default:
                    imageViewCircleNew.setVisibility(View.INVISIBLE);
                    eyeBlink.inCircle(false);

            }
        } else {
            imageViewCircleNew.setVisibility(View.INVISIBLE);
            eyeBlink.inCircle(false);
        }
    }


    int detectFaceInside(int overlaySize, float faceWidth, float faceHeight) {
        int i = 0;
        float diffWidth = overlaySize - faceWidth;
        float diffHeight = overlaySize - faceHeight;

        if (-250 < diffWidth && diffWidth < 250 && -250 < diffHeight && diffHeight < 250) {
            i = 1;
        } else {
            if (diffWidth < -250 && diffHeight < -250) {
                i = 2;
            } else {
                i = 0;
            }
        }

        return i;
    }

    public static int dpToPx(int dp) {
        return (int) (dp * Resources.getSystem().getDisplayMetrics().density);
    }

}

interface updateEyeBlink {
    public void inCircle(boolean inCircle);
}