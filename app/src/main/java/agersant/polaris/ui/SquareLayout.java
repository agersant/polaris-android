package agersant.polaris.ui;

import android.content.Context;
import android.content.res.TypedArray;
import android.util.AttributeSet;
import android.widget.FrameLayout;

import agersant.polaris.R;

public class SquareLayout extends FrameLayout {

    private boolean preserveWidth = true;

    public SquareLayout(Context context) {
        super(context);
    }

    public SquareLayout(Context context, AttributeSet attrs) {
        super(context, attrs);
        readAttributes(context, attrs);
    }

    public SquareLayout(Context context, AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
        readAttributes(context, attrs);
    }

    private void readAttributes(Context context, AttributeSet attrs) {
        TypedArray arr = context.obtainStyledAttributes(attrs, R.styleable.SquareLayout);
        boolean preserveWidthArg = arr.getBoolean(R.styleable.SquareLayout_preserveWidth, true);
        setPreserveWidth(preserveWidthArg);
        arr.recycle();
    }

    @Override
    protected void onMeasure(int widthMeasureSpec, int heightMeasureSpec) {
        super.onMeasure(widthMeasureSpec, heightMeasureSpec);
        int squareSize;
        if (preserveWidth) {
            squareSize = getMeasuredWidth();
        } else {
            squareSize = getMeasuredHeight();
        }
        int measureSpec = MeasureSpec.makeMeasureSpec(squareSize, MeasureSpec.EXACTLY);
        super.onMeasure(measureSpec, measureSpec);
    }

    private void setPreserveWidth(boolean preserveWidth) {
        this.preserveWidth = preserveWidth;
    }
}
