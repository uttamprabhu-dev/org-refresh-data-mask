import { LightningElement, track } from 'lwc';

const redactionCriteria = [
    {
        type: 'PHONE',
        startChar: 1,
        endChar: 10,
        info: '',
        dropdown: true
    },
    {
        type: 'EMAIL',
        startChar: 1,
        endChar: 20,
        info: '',
        dropdown: true
    },
    {
        type: 'STRING',
        startChar: 1,
        endChar: null,
        info: '',
        dropdown: false
    },
]

export default class Or_customComponent extends LightningElement {
    fieldRedactionCriteria = redactionCriteria;
}