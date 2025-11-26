import { LightningElement } from 'lwc';
import getUserColor from '@salesforce/apex/PreferenceColor.getUserColor';
import NOTICE_BOARD_HEADING from '@salesforce/label/c.NoticeBoardHeading';
import NOTICE_BODY from '@salesforce/label/c.Notice_Body';
import REPORT_ERROR from '@salesforce/label/c.ReportError';
import THANK_YOU from '@salesforce/label/c.ThankYou';
 
export default class NoticeBoard extends LightningElement {
    color = 'white';
    noticeHeading = NOTICE_BOARD_HEADING;
    noticeBody = NOTICE_BODY;
    buttonLabel = REPORT_ERROR;
    thankYouLabel = THANK_YOU;
 
    connectedCallback() {
        getUserColor()
            .then(result => {
                this.color = result;
            })
            .catch(() => {
                this.color = 'white';
            });
    }

    renderedCallback(){
        this.template.querySelector('.backgroung').style.backgroundColor = this.color;
    }

    // get containerClass() {
    //     return `notice ${this.color ? this.color.toLowerCase() : 'white'}`;
    // }
 
    handleButtonClick() {
        this.buttonLabel = this.thankYouLabel;
    }
}