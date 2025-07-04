import React from 'react';
import Link from '@docusaurus/Link';
import styles from './styles.module.css';

const ConsoleButton = ({ 
    className,
    ...props 
}) => {
    return (
        <Link 
            to="https://console.meteoscientific.com/front/"
            target="_blank"
            rel="noopener noreferrer"
            className={`${styles.consoleButtonSvg} ${className || ''}`}
            {...props}
        >
            <img 
                src="/img/buttons/console-button.svg" 
                alt="Open MeteoScientific Console"
                className={styles.consoleButtonImage}
            />
        </Link>
    );
};

export default ConsoleButton; 